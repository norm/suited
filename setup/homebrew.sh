local existed

# enforce the directory exists
[ -d "$HOMEBREW_PREFIX" ] || sudo mkdir -p "$HOMEBREW_PREFIX"
sudo chown -R "$USER:admin" "$HOMEBREW_PREFIX"

# setup the git directory, and checkout homebrew
# (this is destructive if you have an existing homebrew
# checkout with uncommitted local modifications)
export GIT_DIR="$HOMEBREW_PREFIX/.git"
export GIT_WORK_TREE="$HOMEBREW_PREFIX"
[ -d "$GIT_DIR" ] && existed=1

status 'cloning Homebrew'
git init
git config remote.origin.url 'https://github.com/Homebrew/brew'
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
if [ -n $existed ]; then
    git fetch
else
    git fetch --no-tags --depth=1 --force --update-shallow
fi
git reset --hard origin/master
unset GIT_DIR GIT_WORK_TREE

# update (will this actually do anything after the reset above?)
status 'updating Homebrew'
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
brew update

# install homebrew bundle, cask, services and versions
brew bundle --file=- <<EOF
    tap 'caskroom/cask'
    tap 'homebrew/core'
    tap 'homebrew/services'
    tap 'homebrew/versions'
EOF
