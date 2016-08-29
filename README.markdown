suited
======

Set up your Mac OS X development environment as a lone developer, or as
part of a team.

## How it works

Running `bash suited.sh` without any arguments will look for a file
`main.conf` in the current working directory and try to satisfy its contents.

If an argument is given (eg `bash suited.sh path/to/suited/files` or
`bash suited.sh https://example.com`), then that is used as the base directory
that all relative filenames are to be found in. Suited will still look for a
file `main.conf` in that directory to start from.


## suited's configuration file

An example of the things you can specify in your file:

  * lines starting with a hash are comments and are ignored
  * lines that end `Brewfile` (case insensitive) are installed by
    [Brew Bundle](https://github.com/Homebrew/homebrew-bundle) with
    `brew bundle --file`
  * lines that end `.sh` are sourced (executed in the same shell process)
  * lines starting with `github:` are repositories you want to work on, so
    they are:
      * checked out to `~/Code/owner/repo`
      * if a file `Brewfile` exists in the root, it is installed
      * if a file `scripts/bootstrap` exists, it is sourced
  * anything else is interpreted as another config file, and processed as
    per this list

Note:

  * instances of `$USER` are replaced with the current username
  * instances of `$HOST` are replaced with the output of
    `hostname -s` (but also see environment settings below)
  * instances of `$GITHUB_USER` are replaced with the contents of
    that environment variable
  * no other variables are interpolated

See `main.conf.example` for an illustration of what a config file might look
like.


## Environment variables

Some environment variables can be set before running `suited.sh` to influence
how things are setup:

  * If using `setup/git.sh`:

      * `GIT_NAME` should be the full name to use when committing
      * `GIT_EMAIL` should be the email address to use when committing
      * `GITHUB_USER` should be the GitHub account

    Note, though, that these will be prompted for if the environment
    variables are not set.

  * `HOMEBREW_PREFIX` is where Homebrew should be installed
    (defaults to `/usr/local`)
  * `HOST` is the string to treat as the first part of the hostname of the
    computer, if you are using that in any config lines (defaults to
    the output of `hostname -s`)
  * `REPO_DIR` is the base directory GitHub repositories are checked out into
    (defaults to `~/Code`)


## Using `suited`

There are two approaches to using suited to setup a new Mac:

 1. Fork this repo, `cp suited.conf.example main.conf` and edit it to
    match your desired setup.
 2. Create a new repo for keeping your setups in, and refer to anything
    you want from this repo with the full URL
    (like [my suit repo](https://github.com/norm/suit) does).

Forking is probably easier if you need to change any of the setup scripts,
starting afresh is probably easier if you don't. Either way, after you
have edited the configurations you are going to use:

    export GIT_NAME='Your Full Name'
    export GIT_EMAIL='you@example.com'
    export GITHUB_USER='you'
    curl -O https://raw.githubusercontent.com/norm/suited/master/suited.sh
    bash suited.sh https://raw.githubusercontent.com/your/repo/master

If you have a copy of your setup repo on the local disk (eg after having setup
your Mac, and you are testing changes to the setup), you can run it against
those files instead:

    bash suited.sh ~/Code/your/repo

Note: in order to check out any GitHub repositories, you will need to have
an SSH key active on the Mac, and have registered it with GitHub.

## Why yet another macOS/OSX bootstrapper

Why create another bootstrapper for your Mac computer? There are already
many other systems, such as:

  * [battleschool](https://github.com/spencergibb/battleschool)
  * [boxen](https://github.com/boxen/our-boxen)
  * [chef-osx](http://chef-osx.github.io)
  * [dev-setup](https://github.com/donnemartin/dev-setup)
  * [laptop](https://github.com/thoughtbot/laptop)
  * [mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook)
  * [osxc](https://osxc.github.io)
  * [strap][strap]
  * [vanilla Puppet](http://blog.tfnico.com/2016/03/replacing-boxen-with-vanilla-puppet-for.html)
  * [workstation-chef](https://github.com/jtimberman/workstation-chef-repo)

One reason to create this is to minimise the amount of **stuff** needed
to write in order to setup a new laptop.

Another reason is frustration with the fragility of using software like
puppet to only partially manage a machine — GitHub have abandoned using
boxen ([replacing it with strap][blog-strap]) for similar reasons.

Another is that whilst something like [strap][strap] (which is little more
than a bit of shell setup and then using Homebrew) is almost what I wanted,
I still missed the ability for multiple users to collaborate on setups,
as when using boxen (a great example was the [GDS boxen][gds-boxen]).

So here is `suited` (taken from the phrase [suited and booted][sb], but you
can pretend it is a reference to making a computer suitable for use).

[blog-strap]: http://mikemcquaid.com/2016/06/15/replacing-boxen/
[gds-boxen]: https://github.com/alphagov/gds-boxen
[sb]: https://en.wiktionary.org/wiki/suited_and_booted
[strap]: https://github.com/mikemcquaid/strap
