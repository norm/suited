local name
local email
local github

if ! git config user.name >/dev/null; then
    if [ -n "$GIT_NAME" ]; then
        git config --global user.name "$GIT_NAME"
    else
        read -p "Full name: " name
        git config --global user.name "$name"
    fi
fi

if ! git config user.email >/dev/null; then
    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
    else
        read -p "Email address: " email
        git config --global user.email "$email"
    fi
fi

if ! git config github.user >/dev/null; then
    if [ -n "$GITHUB_USER" ]; then
        git config --global github.user "$GITHUB_USER"
    else
        read -p "Github user: " github
        git config --global github.user "$github"
    fi
fi
