local existed
local -a required_dirs=(Cellar Frameworks bin etc include lib opt sbin share var)


# enforce the path for all homebrew installed software exists
[ -d "$HOMEBREW_PREFIX" ] \
    || sudo mkdir -p "$HOMEBREW_PREFIX"
sudo chown -R "root:wheel" "$HOMEBREW_PREFIX"

silent_pushd $HOMEBREW_PREFIX
sudo mkdir -p "${required_dirs[@]}"
sudo chown -R "$USER:admin" "${required_dirs[@]}"
silent_popd

# enforce the path for the homebrew repository exists
[ -d "$HOMEBREW_REPOSITORY" ] \
    || sudo mkdir -p "$HOMEBREW_REPOSITORY"
sudo chown -R "$USER:admin" "$HOMEBREW_REPOSITORY"

# ensure brew can be found in $PATH later
[ "$HOMEBREW_REPOSITORY" != "$HOMEBREW_PREFIX" ] \
    && sudo ln -sf "$HOMEBREW_REPOSITORY/bin/brew" "$HOMEBREW_PREFIX/bin/brew"

# setup the git directory, and checkout homebrew
# (this is destructive if you have an existing homebrew
# checkout with uncommitted local modifications)
export GIT_DIR="$HOMEBREW_REPOSITORY/.git"
export GIT_WORK_TREE="$HOMEBREW_REPOSITORY"
[ -d "$GIT_DIR" ] \
    && existed=1

status 'cloning Homebrew'
git init
git config remote.origin.url 'https://github.com/Homebrew/brew'
git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
[ -n $existed ] \
    && git fetch \
    || git fetch --no-tags --depth=1 --force --update-shallow

git reset --hard origin/master
unset GIT_DIR GIT_WORK_TREE

# update homebrew internals
status 'updating Homebrew'
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
brew update

# install homebrew bundle, cask, services and versions
brew bundle --file=- <<EOF
    tap 'caskroom/cask'
    tap 'homebrew/core'
    tap 'homebrew/services'
EOF
