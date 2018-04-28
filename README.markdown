suited
======

Set up your Mac OS X development environment as a lone developer, or as
part of a team.

## Quick example usage and suitfile

From a fresh install of macOS/OS X, create an account that can administer
the computer.

Open the Terminal application and setup some environment variables.

    export GIT_NAME='Wendy Testaburger'
    export GIT_EMAIL='wendy@example.com'
    export GITHUB_USER='wendy'

Create a new GitHub [personal access token][token] with at least the `repo`
and `write:public_key` scopes active. Copy the token into your environment.

    export GITHUB_TOKEN='123abc...'

Create a new SSH key and register it with GitHub (or copy an existing one
you already have to your computer).

```bash
# create key and add to the ssh-agent
ssh-keygen -trsa -b4096 -C "$GIT_EMAIL" -f $HOME/.ssh/id_rsa
ssh-add $HOME/.ssh/id_rsa

# upload new key to GitHub
pubkey=$( cat $HOME/.ssh/id_rsa.pub )
json=$( printf '{"title": "%s", "key": "%s"}' "$GIT_EMAIL" "$pubkey" )
curl -d "$json" https://api.github.com/user/keys?access_token=$GITHUB_TOKEN
```

Fetch `suited.sh` and run it, telling it which file(s) to use to setup
your computer. They can be relative or absolute path, URLs or special 
github notation (as explained in [the suitfile documentation][sfd]).

    curl -O https://raw.githubusercontent.com/norm/suited/latest/suited.sh
    bash suited.sh github:wendy/suit:main.conf

Alternatively, an argument of a hyphen (`-`) means to use standard input
as the suitfile:

    echo "github:wendy/suit:Brewfile" | bash suited.sh -


[token]: https://github.com/settings/tokens
[sfd]: documentation/suitfile.markdown##relative-and-absolute-paths-and-urls


### Example suitfile

    # setup xcode, homebrew and git
    github:norm/suited:setup/install_xcode.sh
    github:norm/suited:setup/homebrew.sh
    github:norm/suited:setup/git.sh

    # personal software
    github:wendy/suit:Brewfile

    # checkout code
    repo wendy/suit
    repo wendy/dotfiles

    # lastly, ensure software is up to date
    github:norm/suited:setup/software_update.sh


## More documentation

You should read these before getting starting with `suited`:

  * [Using suited](documentation/usage.markdown)
  * [The suitfile in depth](documentation/suitfile.markdown)

I keep my setup [in a separate public repo](https://github.com/norm/suit/),
to serve as a reference example of how to use `suited`.


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
