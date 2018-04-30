Setting up a new macOS computer
===============================

The initial software and code setup for my personal computers,
for use with [suited](https://github.com/norm/suited).


## macOS account setup

During the installation of macOS

* don't sign into iCloud during the finalisation
* create alternate `king` account, not `norm`

Once logged in, open System Preferences and:

* create the `norm` account
* turn off fast user switching
* set the login window to display as "Name and password"
* change the hostname in the Sharing pane

Log out, then back in as `norm`, signing into iCloud during the finalisation.


## Copy preferences

Some preferences are hard to set using `defaults write`, so copy the files wholesale.
Run this command, then immediately log out:
```
nohup sh -c '
    sleep 20;
    cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/kit/prefs/* ~/Library/Preferences
' &
```

Only log back in after waiting for more than 20 seconds to have passed.

## Software installation and environment customisation 

Copy your ssh key into place and activate it with `ssh-add`.

Explicitly sign into the Mac App Store application: Store → Sign In… 

Run suited:

```
export GITHUB_TOKEN=____TOKEN_GOES_HERE____
export GITHUB_USER='norm'
export GIT_EMAIL='norm@201created.com'
export GIT_NAME='Mark Norman Francis'
export HOST=`hostname -s`
curl -O https://raw.githubusercontent.com/norm/suited/master/suited.sh 
bash suited.sh github:norm/suit:initial_setup.conf
```

Reboot once suited has run successfully all the way through.


Run suited again, now installed to `/usr/local/bin`, with the same environment settings:

```
export ...

# set up the mac with my personal settings
suited github:norm/suit:preferences.conf

# lastly, check out common code libraries I use and refer to
suited github:norm/suit:code_library.conf
```
