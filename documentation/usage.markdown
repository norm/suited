Using suited
============

After downloading `suited.sh` to your computer, run it and tell it where
to find your setup configuration.

You can give `suited.sh` multiple arguments, and it will use each in turn.
For example, I setup a new computer like so:

    # ...export all the things mentioned in the README...
    curl -O https://raw.githubusercontent.com/norm/suited/master/suited.sh
    bash suited.sh github:norm/suit:main.conf


## Environment variables

Some environment variables can be set before running `suited.sh` to influence
how things are setup:

  * If you want to access private repositories, `GITHUB_TOKEN` needs to
    be set to a token with at least the `repo` scope active.

  * If using `setup/git.sh`:

      * `GIT_NAME` should be the full name to use when committing
      * `GIT_EMAIL` should be the email address to use when committing
      * `GITHUB_USER` should be the GitHub account

    Note, though, that these will be prompted for if the environment
    variables are not set.

  * If using `setup/homebrew.sh`, setting `HOMEBREW_PREFIX` will override
    where the default of installing Homebrew into `/usr/local`.

  * If using `$HOST` in any configuration lines to do things specific to
    one computer, setting `HOST` will override the default of the output
    of `hostname -s`.

  * If using `repo` to clone repositories for later use, `REPO_DIR` will
    override the default of cloning them into `~/Code` (this can also
    be overridden on a per-repository basis in the configuration file).


## Invoking `suited`

There are two approaches to using suited to setup a new Mac:

 1. Fork this repository, `cp suited.conf.example main.conf` and edit it to
    match your desired setup.

    This is recommended for people using any of the `setup/` scripts that
    don't want them to change without noticing. After all, you are 
    trusting a third-party with root access to your computer.

 2. Create a new repository, gist, file(s) on a web server, or local file(s)
    for keeping your setups in, and refer to anything you want from this
    repository with the shorthand URLs `github:norm/suited:...`
    (like [my suit repository](https://github.com/norm/suit) does).

    This is recommended for more trusting and/or lazy people who want to
    keep their settings separate from this code.

I keep my personal setup in
[a separate repository](https://github.com/norm/suit/) from `suited` on my
local filesystem, so that I can adjust my settings and test them locally
first:

    bash suited.sh ~/Code/norm/suit/main.conf

Then once I am happy, I push it to GitHub so that the next time I am setting
up a new Mac, I can just type:

    bash suited.sh github:norm/suit:main.conf


## Collaborating

If you want to use `suited` in a team environment, I recommend sharing your
`suited` configurations in a repository.

Use the `user/$USER/main.conf` pattern so that each developer has their own
space to add the software and configuration unique to them.

Create separate projects/teams files (eg. `team/frontend/main.conf`) that
define the software and repositories needed. Then as users join a given
project/team, they can include that in their config file:

    # working in the frontend team
    team/frontend/main.conf

Any software required by a specific repository should be kept in `Brewfile`,
`Gemfile`, or be installed in `script/bootstrap` rather than shared in the
team configuration. This also acts as a form of setup documentation.
