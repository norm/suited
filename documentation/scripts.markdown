setup scripts
=============

`suited` provides several scripts that perform actions commonly done
during the setup of a new Mac.

You can use them in your own suitfiles by including them directly, like:

    # setup Homebrew (http://brew.sh)
    github:norm/suited:setup/homebrew.sh

You can also use a specific version, if you like knowing exactly what will
happen:

    # setup Homebrew (http://brew.sh)
    github:norm/suited@fe24e43:setup/homebrew.sh



## full_disk_encryption.sh

Confirms that full-disk encryption is turned on. If it is not, it is enabled
and the newly created recovery key is copied to a file on the Desktop.


## password_after_screensaver.sh

Sets the security preferences to ask for a password after the screensaver
has started, but only after 5 seconds have passed.


## xcode.sh

Installs the Xcode Command Line Tools. Recommended as they are required to
build software.

Required by Homebrew.


## homebrew.sh

Installs Homebrew. Recommended for installing any command-line tools,
Applications and to download software from the Mac App Store as part of
setting up a new Mac.


## git.sh

Creates the settings `user.name`, `user.email` and `github.user` in the file
`~/.gitconfig` if they are not already set. Generally controlled by the
[environment variables][env] set before running `suited`, but will also prompt
if they are unset.

[env]: documentation/usage.markdown#environment-variables


## ruby_with_rbenv.sh

Installs [rbenv][rbenv] to manage [Ruby][ruby] versions and gem dependencies,
installs the latest version of ruby as the global version, then installs
[bundler][bundler].

Required if any repositories checked out during setup contain a `Gemfile`
(as `suited` will try to run `bundler`).

[rbenv]: https://github.com/rbenv/rbenv
[ruby]: https://www.ruby-lang.org/en/
[bundler]: http://bundler.io


## clone_starred_repos.sh

This will checkout all repositories on GitHub that `GITHUB_USER` has
starred.


## software_update.sh

Will install any outstanding macOS software updates.

Recommended (in order to have security updates applied ASAP). Probably best to
be included last, as some updates can be large downloads.


## apply_defaults.sh

Documented in [apply_defaults](apply_defaults.markdown).


## install_suited.sh

Moves the version of suited in use to /usr/local/bin/suited. Useful to put
at the end of your main setup suitfile so that suited is then more easily
available for re-running later.
