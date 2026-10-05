#!/usr/bin/env python3
"""Block an expensive model switch until the context has been compacted.

Why this exists
---------------
The prompt cache is per-model. Switching models throws it away: everything in
context is re-read by the new model as *fresh* input, at full rate, with no
cache discount. A session sitting on 340k tokens — of which 337k were cache
reads at 0.1x — costs about $1.70 to re-read on Opus 5 the moment you switch,
against $0.17 while the cache was warm. Compacting to ~20k first makes it about
$0.10.

So on a large context this hook blocks the switch once and says so. It is a
speed bump, not a wall: repeat the same switch within the grace window and it
goes through, because a hook you cannot get past is a hook you disable.

It fails open. Anything it cannot measure or parse is allowed — never block a
model switch because a helper script had a bad day.

Configuration (environment):
  CLAUDE_SWITCH_MAX_TOKENS   block above this live context size (default 50000)
  CLAUDE_SWITCH_GRACE_SECS   window in which a repeat switch is allowed (default 180)
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

THRESHOLD = int(os.environ.get("CLAUDE_SWITCH_MAX_TOKENS", "50000"))
GRACE = int(os.environ.get("CLAUDE_SWITCH_GRACE_SECS", "180"))
MARKER = Path.home() / ".cache" / "claude-model-switch-intent.json"
# Written by the llm-price-check skill; used for a live input price if present.
PRICES = Path.home() / ".cache" / "llm-price-check.json"


def allow() -> int:
    return 0


def live_context_tokens(transcript: Path) -> int | None:
    """Tokens currently in context, from the last assistant turn's usage.

    input + cache_read + cache_creation is what the model actually saw, which
    is the number that gets re-read on a switch. Reading the file size instead
    would be wrong: the transcript keeps everything, including what compaction
    has already dropped.
    """
    if not transcript.is_file():
        return None
    last = None
    try:
        with transcript.open(encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if '"assistant"' not in line or '"usage"' not in line:
                    continue
                try:
                    usage = (json.loads(line).get("message") or {}).get("usage")
                except json.JSONDecodeError:
                    continue
                if usage:
                    last = usage
    except OSError:
        return None
    if not last:
        return None
    return sum(
        int(last.get(key) or 0)
        for key in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")
    )


def input_price(model: str) -> float | None:
    """USD per million input tokens for *model*, if we happen to know it."""
    if not PRICES.is_file():
        return None
    try:
        data = json.loads(PRICES.read_text())
    except (OSError, json.JSONDecodeError):
        return None

    def norm(text: str) -> str:
        return "".join(c for c in text.lower() if c.isalnum())

    want = norm(model)
    best = None
    for entry in data.get("models", []):
        if entry.get("vendor") != "Anthropic":
            continue
        name = norm(entry.get("base_name", ""))
        # "claude-opus-5[1m]" -> "claudeopus51m"; match on the model name being
        # a prefix of it, longest wins.
        if name and want.startswith(name) and isinstance(entry.get("input"), (int, float)):
            if best is None or len(name) > best[0]:
                best = (len(name), float(entry["input"]))
    return best[1] if best else None


def repeat_of(from_model: str, to_model: str) -> bool:
    """True when this exact switch was just attempted and blocked."""
    if not MARKER.is_file():
        return False
    try:
        marker = json.loads(MARKER.read_text())
    except (OSError, json.JSONDecodeError):
        return False
    return (
        marker.get("from") == from_model
        and marker.get("to") == to_model
        and time.time() - float(marker.get("at", 0)) < GRACE
    )


def remember(from_model: str, to_model: str) -> None:
    try:
        MARKER.parent.mkdir(parents=True, exist_ok=True)
        MARKER.write_text(json.dumps({"from": from_model, "to": to_model, "at": time.time()}))
    except OSError:
        pass


def block(reason: str) -> int:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreModelSwitch",
            "decision": "block",
            "reason": reason,
        }
    }))
    return 2


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return allow()

    from_model = str(event.get("from_model") or "?")
    to_model = str(event.get("to_model") or "?")

    if repeat_of(from_model, to_model):
        try:
            MARKER.unlink()
        except OSError:
            pass
        return allow()

    transcript = event.get("transcript_path")
    if not transcript:
        return allow()

    tokens = live_context_tokens(Path(transcript))
    if tokens is None or tokens <= THRESHOLD:
        return allow()

    price = input_price(to_model)
    if price is not None:
        cost = tokens / 1_000_000 * price
        money = f" That is about ${cost:.2f} at {to_model}'s ${price:g}/MTok input rate."
    else:
        money = ""

    remember(from_model, to_model)
    return block(
        f"Context is ~{tokens:,} tokens. The prompt cache does not survive a model "
        f"switch, so {to_model} would re-read all of it as fresh input at full "
        f"rate.{money}\n\n"
        f"Run /compact first, then switch — or just repeat the switch within "
        f"{GRACE // 60} minutes and it will go through unblocked."
    )


if __name__ == "__main__":
    raise SystemExit(main())
