local destination
local page_count
local repo_list


# must have the token set, otherwise you are likely to hit rate limiting
[ -z "$GITHUB_TOKEN" ] \
    && abort "GITHUB_TOKEN needs to be set to clone starred repos."

# must have the user set, otherwise what repos are you cloning?
[ -z "$GITHUB_USER" ] \
    && abort "GITHUB_USER needs to be set to clone starred repos."

page_count=$(
    curl --head --silent -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/users/$GITHUB_USER/starred \
            | grep ^Link: \
            | sed -e 's/.*page=.*page=//' -e 's/>.*//'
)

for page in $(seq 1 $page_count); do

    repo_list=$(
        curl --silent -H "Authorization: token $GITHUB_TOKEN" \
            https://api.github.com/users/$GITHUB_USER/starred?page=$page \
                | grep full_name \
                | awk -F\" '{ print $4 }'
    )

    for repo in $repo_list; do
        destination="${REPO_DIR}/$repo"
        if [ ! -d "$destination" ]; then
            status "checkout '$repo'"
            mkdir -p "$destination"
            git clone git@github.com:${repo}.git "$destination"
        else
            status "update '$repo'"
            update_git_clone "$destination"
        fi
    done

done
