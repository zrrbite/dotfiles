#!/bin/bash
# Screen recording helper for wf-recorder

RECORDINGS_DIR="$HOME/Videos/Recordings"
PIDFILE="/tmp/wf-recorder.pid"

mkdir -p "$RECORDINGS_DIR"

start_recording() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Recording" "Already recording! Press Super+Shift+R to stop."
        exit 1
    fi

    FILENAME="$RECORDINGS_DIR/$(date +%Y%m%d_%H%M%S).mp4"

    case "$1" in
        region)
            GEOMETRY=$(slurp)
            [ -z "$GEOMETRY" ] && exit 1
            wf-recorder -g "$GEOMETRY" -f "$FILENAME" &
            ;;
        audio)
            wf-recorder --audio -f "$FILENAME" &
            ;;
        region-audio)
            GEOMETRY=$(slurp)
            [ -z "$GEOMETRY" ] && exit 1
            wf-recorder -g "$GEOMETRY" --audio -f "$FILENAME" &
            ;;
        *)
            wf-recorder -f "$FILENAME" &
            ;;
    esac

    echo $! > "$PIDFILE"
    notify-send "Recording Started" "Saving to $FILENAME"
}

stop_recording() {
    if [ -f "$PIDFILE" ]; then
        kill -INT $(cat "$PIDFILE") 2>/dev/null
        rm "$PIDFILE"
        notify-send "Recording Stopped" "Saved to ~/Videos/Recordings"
    else
        notify-send "Recording" "No recording in progress"
    fi
}

toggle_recording() {
    if [ -f "$PIDFILE" ]; then
        stop_recording
    else
        start_recording "$1"
    fi
}

case "$1" in
    start)   start_recording "$2" ;;
    stop)    stop_recording ;;
    toggle)  toggle_recording "$2" ;;
    *)
        echo "Usage: $0 {start|stop|toggle} [region|audio|region-audio]"
        echo ""
        echo "Examples:"
        echo "  $0 start          # Record full screen"
        echo "  $0 start region   # Record selected region"
        echo "  $0 start audio    # Record full screen with audio"
        echo "  $0 stop           # Stop recording"
        echo "  $0 toggle         # Toggle recording on/off"
        exit 1
        ;;
esac
