setup/apply_shortcuts.sh
========================

For easier overriding of keyboard shortcuts.

By default uses the directory `~/etc/macos/shortcuts`, but this can be
overridden with the environment variable `MACOS_SHORTCUTS_DIR`.

Within this directory, create a file named for the macOS defaults domain of
the targeted application. For example, Safari saves its preferences in the
file `~/Library/Preferences/com.apple.Safari.plist`, so you would use
`com.apple.Safari`.

The file should look something like:

    # prefer arrows to curly braces
    Show Next Tab                 cmd-opt-right
    Show Previous Tab             cmd-opt-left
    
    # used often enough to warrant a shortcut
    Disable JavaScript              cmd-opt-J

Lines starting with a hash (`#`) are considered comments, and ignored.

The menu entry to change is on the left, the shortcut is on the right; they
need to be separated by *at least* two whitespace characters.

The shortcut can contain the following human-readable shorthands for keys:

  * `F1` through `F12`
  * `command` or `cmd`
  * `option` or `opt` or `alt`
  * `shift`
  * `control` or `ctrl`
  * `left` (for the left arrow key)
  * `right` (for the right arrow key)
  * `up` (for the up arrow key)
  * `down` (for the down arrow key)

Keys can be separated with either hyphens (`-`) or pluses (`+`).


## Example

As an example, see [my shortcuts repository][cuts], which I check out during
setup with this line in a suitfile:

    repo  github:norm/macos_shortcuts  ~/etc/macos/shortcuts

[cuts]: https://github.com/norm/macos_shortcuts
