setup/apply_defaults.sh
=======================

For easier setting of defaults (system and application preferences).

By default uses the directory `~/etc/macos/defaults`, but this can be
overridden with the environment variable `MACOS_DETAULTS_DIR`.

Within this directory, create a file named for the macOS defaults domain of
the targeted application. For example, Safari saves its preferences in the
file `~/Library/Preferences/com.apple.Safari.plist`, so you would use
`com.apple.Safari`.

For example, to apply:

    defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

create a file `~/etc/macos/defaults/com.apple.Safari` and put in it:

    AutoOpenSafeDownloads -bool false

Lines starting with a hash (`#`) are considered comments, and ignored.

If a line starts KILL then killall will be run against the remainder of the
line; for example `KILL Dock` will run `killall Dock` (some processes need to
be restarted to see the applied defaults).


## Setting keyboard shortcuts

Whilst keyboard shortcuts are modified using `defaults write`, this can also
be done more easily by using [apply_shortcuts](apply_shortcuts.markdown).


## Example

As an example, see [my defaults repository][defs], which I check out during
setup with this line in a suitfile:

    repo  github:norm/macos_defaults  ~/etc/macos/defaults

[defs]: https://github.com/norm/macos_defaults
