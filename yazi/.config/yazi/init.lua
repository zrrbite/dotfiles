-- yazi startup script. Plugins come from package.toml (`ya pkg install`
-- fetches them into plugins/, which is gitignored); this file only sets them
-- up.

-- git.yazi: a status sign beside each file in a git repo (modified, added,
-- untracked, ignored...). Needs the fetchers registered in yazi.toml.
require("git"):setup {
	order = 1500,
}
