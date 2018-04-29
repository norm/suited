Changes to suited
=================

All notable changes to `suited` will be documented in this file.


Unreleased
----------

### Added

* New suitfile command `symlink` to create symbolic links.


0.9 — 2018-04-29
----------------

### *Important change*

Previous instructions for using suited recommended fetching `suited.sh`
from the `master` branch. It is now recommended that you fetch `suited.sh`
from the `latest` branch. This will be the most recent released version,
rather than whatever is currently waiting to be released — which may include
breaking changes.

### Added

* `suited` no longer reexecutes itself, which should make for more
  predictable debugging and execution.
* More boilerplate filenames (eg. LICENSE) are ignored when appying
  `setup/apply_defaults.sh` and `setup/apply_shortcuts.sh`.
* When naming a directory in a suitfile, now assume applying the `suitfile`
  within. This allows greater flexibility, as everything `suited` can do
  is now available, rather than a random subset.

### Changed

* The output of suited has been tweaked (different colours and spacings),
  and the commands to output formatted text added to the suitfile definition.

### Fixed

* `suited` will create the `~/.ssh` directory if it doesn't already exist
  (which stops it breaking when trying to add to the `known_hosts` file).

### Deprecated

* The behaviour of naming a directory in a suitfile and having it process
  the `Brewfile`, ruby versions and gems, and more is now deprecated in
  favour of using an explicit `suitfile` in the directory.

### Removed

* The `homebrew/versions` tap was removed, as it was deprecated by Homebrew.
* `suited` no longer reports "All done... [etc] ...!" when it exits
  successfully.


0.8.2 — 2017-07-17
------------------

### Fixed

* `suited` now respects the patch level in suited versions. (0.8.1 wasn't
  seen as newer than 0.8).


0.8.1 — 2017-07-17
------------------

### Fixed 

* Corrects the instructions for upgrading suited.


0.8 — 2017-04-24
----------------

### Added

* A suitfile can now use `clone` to clone a Github repo without performing
  all of the setup that `repo` does.

### Fixed

* Homebrew is checked out to `/usr/local/Homebrew` (which is a recent change
  to how the homebrew setup script now behaves).


0.7 — 2017-04-23
----------------

### Added

* Added `setup/install_suited.sh` script to install the downloaded version of
  suited to `/usr/local/bin/suited`.
* A suitfile can now include `loginitem <Appname>` to add an application
  to the list of Login Items.

### Fixed

* `setup/clone_starred_repos.sh` will abort if the `GITHUB_TOKEN` and
  `GITHUB_USER` environment variables are not set (previously just reported
  as error and then the script failed anyway).


0.6 — 2016-10-29
----------------

### Added

* `suited -v` will report the current version number, and tell you if
  it is out-of-date compared to the version on Github.
* `suited -u` will fetch the latest version from Github and replace your
  current copy with it.
* `suited -h` will report usage information.


0.5 — 2016-10-29
----------------

Start of versioning. Previous changes are available in the git history,
if you're interested enough to go looking.
