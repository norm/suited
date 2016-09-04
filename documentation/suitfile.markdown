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

    Any line that starts `repo` is used to check out a repository.

    The second argument should be of the form `github:norm/suited` (only github
    repositories are currently supported).

    An optional third argument is where the code should be cloned to. By
    default it will be checked out into `~/Code`, in a subdirectory reflecting
    the repository and user (eg. `norm/suited` will be cloned in
    `~/Code/norm/suited`). You can use `~` in this argument to mean your home
    directory.

        # things I need
        repo  github:norm/suited
        repo  github:norm/wiki    ~/wiki

    After checking out a repository, `suited` will check for the following
    files in it:

      * `Brewfile` — if this exists, `suited` will use it to install any
        software dependencies
      * `Gemfile` — it this exists, `suited` will use it to install any
        Gems (it is assumed that ruby is setup at this point, you can
        use `setup/ruby_with_rbenv.sh` in your setup for example)
      * `script/bootstrap` — if this exists, `suited` will source it
        (using GitHub's [scripts pattern](https://github.com/github/scripts-to-rule-them-all))

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
