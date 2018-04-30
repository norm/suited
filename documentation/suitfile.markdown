The suitfile
============

The "suitfile" is the configuration file that tells `suited` what to do.
It can contain:

  * **comments**

    Any line starting with a hash (`#`) is ignored. Whitespace can appear before
    the hash.

        # I am a comment.

            # Me too.

  * **Brewfiles**

    Any line that ends `Brewfile` (case insensitive) is used to install software
    using [Brew Bundle](https://github.com/Homebrew/homebrew-bundle) (with
    the command `brew bundle --file`).

        # Add some software
        user/norm/Brewfile

  * **Dockfile**

    Any line that ends `Dockfile` (case insensitive) is used to modify the
    contents of the Dock (see [dockfile explanation](dockfile.markdown)).

  * **Gemfiles**

    Any line that ends `Gemfile` (case insensitive) is used to install gems
    using [bundler](http://bundler.io) (with the command 
    `bundle install --gemfile`).

        # Add dependencies
        user/norm/Gemfile

  * **scripts**

    Any line that ends `.sh` is sourced (executed in the same shell process).

        # set stuff up
        setup/install_xcode.sh

  * **repositories**

    There are two ways to locally clone repositories:

    1. Any line that starts `clone` is used to clone a repository.

        The second argument should be of the form `github:norm/suited` (only
        github repositories are currently supported).

        An optional third argument is where the code should be cloned to. By
        default it will be checked out into `~/Code`, in a subdirectory
        reflecting the repository and user (eg. `norm/suited` will be cloned
        in `~/Code/norm/suited`). You can use `~` in this argument to mean
        your home directory.

            # things I need
            repo  github:norm/suited
            repo  github:norm/wiki    ~/wiki

        If running `suited` again, it will do a `git fetch` on a previously
        cloned repository, and if new commits are on master it will 
        `git pull`. You can stop this by setting `SUITED_DONT_PULL_REPOS` 
        to any value.

    2. Any line that starts `repo` is used to clone a repository and then
       set it up. The arguments are identical to `clone` above. Once the
       repository is cloned, it is setup as described in **directories**.

  * **directories**

    Any line that ends `/` is assumed to be a directory which contains a
    `suitfile`. This will be processed by suited before continuing in
    the current suitfile.

    This is an easy way to organise subsets of suited configuration, for
    example by application, user, project or hostname.

    *Deprecated behaviour*

    Previously, the directory would be processed as documented below. This
    will still occur if and only if no `suitfile` exists in the directory.
    `suited` will issue a deprecation warning for every such directory found.

    The directory is checked for the following files which are automatically
    applied, and in this order:

      * `Brewfile` — if this exists, `suited` will use it to install any
        software dependencies
      * `script/bootstrap` — if this exists, `suited` will source it,
        otherwise it will check for:
          * `bootstrap` — if this exists `suited` will source it,
            otherwise it will check for:
              * `.ruby-version` — if this exists, `suited` will use `rbenv` to
                install that version of ruby, and bundler (it is assumed that
                ruby is setup at this point, you can use
                `setup/ruby_with_rbenv.sh` in your setup for example)
              * `Gemfile` — it this exists, `suited` will use it to install
                any Gems (it is assumed that ruby is setup at this point, you
                can use `setup/ruby_with_rbenv.sh` in your setup for example)
      * `crontab` — if this exists, `suited` will add each line of the file
        to your Mac's list of cron jobs if it doesn't already exist.

    Note:

      * There are two different `bootstrap` scripts, provided
        as alternatives. If you are following GitHub's 
        [scripts pattern](https://github.com/github/scripts-to-rule-them-all))
        then use `script/bootstrap`. If not, use `bootstrap`.
      * Ruby and gems are not automatically initialised if either `bootstrap`
        script exists, you must do this yourself.
      * For remote directories (eg. `github:norm/suit:setup/antirsi/`) only
        `Brewfile`, `bootstrap` and `crontab` are checked for, as setting up
        from a directory like this is expected to setup tools, not full-blown
        code repositories.

  * **files to download**

     Any line that starts `download` is used to download a file.

     The second argument is the URL of the file (which can include `github:`
     shortcuts as documented below).

     The third argument is the local destination filename for the file.

        # important things
        download http://bumph.cackhanded.net/norm.jpg ~/Desktop/norm.jpg
        download github:norm/suit:ssh/known_hosts ~/.ssh/known_hosts

  * **symbolic links**

    Any line that starts `symlink` will create a symbolic link. The first
    argument is the source (what the symbolic link points at), the second
    is the target (the symbolic link itself).

      # make .ssh point at etc/ssh
      symlink ~/etc/ssh ~/.ssh

    If the target already exists and is a symbolic link, it will be
    removed and re-created (ie. it is safe to call suitfiles using symlink
    repeatedly). If it exists and is not a symbolic link, suited will
    abort with an error.

  * **login items**

    Any line that starts `loginitem` is used to add an application to
    the list of applications started when the user logs in.

    The second argument is the name of the application.

  * **environment checks**

    Any line that starts `needenv` will check that the argument is an
    environment variable containing a value.

        # setup will fail without a valid token
        needenv GITHUB_TOKEN
        setup_github.sh

  * **text output**

    Suited outputs text formatted in various different ways. These can be
    used in suitfiles:

    * `echo` outputs text
    * `debug` outputs text styled as suited debugging
    * `status` outputs text styled as a status update
    * `action` outputs text styled as a new action being performed
    * `error` outputs text styled as an error message
    * `success` outputs text styled as a success message

    To see examples of the different styles of output available, run 
    `suited github:norm/suited:output-example.suitfile`.

  * **`inform` statements**

    A line that starts `inform` will add the remaining text to the information
    that is presented to the user at the end of processing.

        # reminder
        inform Open 1Password and configure it to use Dropbox.

  * **other suitfiles**

    Any other line is interpreted to mean another suited configuration file, and
    its contents are processed before `suited` continues with the current
    configuration file.

## Relative and absolute paths, and URLs

Any line of a suitfile that points to another file (ie. a Brewfile, Gemfile, 
script, or suitfile) can use a relative or absolute path, or a URL.

  * **absolute path**

    A line starting `/` is seen as an absolute path, and `suited` will try to
    access that file from the root of the computer.

        # execute a script
        /usr/local/bin/script.sh

  * **absolute URL**

    A line starting `http:` or `https:` is seen as a URL, and `suited` will
    use `curl` to fetch the contents of that file.

        # install software
        http://example.com/Brewfile

  * **github:**

    A line starting `github:` is a shorthand form of URL that refers to a file
    in a GitHub repository. Its format is `github:REPO:FILE`. This will be
    expanded to the correct URL to fetch the raw `FILE` from the `REPO`
    repository, even if that repository is private (assuming you have set the
    environment variable `GITHUB_TOKEN` to a token that allows access).

        # ask for a password after locking the computer
        github:norm/suited:setup/password_after_screensaver.sh 

    You can pin the repository to a specific revision of the file (rather than
    using whatever is currently on `master`) by including it in the `REPO`
    argument, like so:

        # only this specific revision
        github:norm/suited@fe24e43:setup/password_after_screensaver.sh

  * **relative path**

    Any other line is interpreted as a path relative to the last absolute
    path.

    For example, if `suited` was processing the file 
    `http://example.com/suited/main.conf`, and it contained a line
    `user/norm/Brewfile`, then `suited` would try to access
    `http://example.com/suited/user/norm/Brewfile`.

    This is true for the `github:` shorthand too — processing a file
    `github:norm/suit:main.conf` which contained the line
    `secret_rails_project/Gemfile`, `suited` would try to access
    a file equivalent to `github:norm/suit:secret_rails_project/Gemfile`.


## Substitutions

Instances of the following are substituted:

  * `$USER` is replaced with the current username
  * `$HOST` is replaced with the output of
    `hostname -s` (but also see environment variables in 
    [usage](usage.markdown))
  * `$GITHUB_USER` is replaced with the contents of that environment variable
  * no other variables are substituted
