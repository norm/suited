local dir="${MACOS_SHORTCUTS_DIR:=${HOME}/etc/macos/shortcuts}"
local args
local menu_entry
local shortcut


if [ -d $dir ]; then
    pushd $dir >/dev/null  # unnecessarily noisy

    for file in *; do
        if [ "$file" != 'README.markdown' ]; then
            status "apply $file"

            if [ "$file" == 'global' ]; then
                args='-globalDomain'
            else
                args="$file"
            fi

            # redirect errors to /dev/null because on a new Mac there will
            # be no NSUserKeyEquivalents, but this isn't an error for us
            defaults delete $args NSUserKeyEquivalents 2>/dev/null || true

            for line in $( cat "$file" ); do
                case "$line" in
                    \#*) # ignore comments
                        ;;

                    *)  menu_entry=$(
                            echo "$line" \
                                | awk -F '[[:space:]][[:space:]]+' \
                                    '{ print $1 }'
                        )
                        shortcut=$(
                            echo "$line" \
                                | awk -F '[[:space:]][[:space:]]+' \
                                    '{ print $2 }' \
                                | perl -pe '
                                    s{\bF1\b}{\\Uf704};
                                    s{\bF2\b}{\\Uf705};
                                    s{\bF3\b}{\\Uf706};
                                    s{\bF4\b}{\\Uf707};
                                    s{\bF5\b}{\\Uf708};
                                    s{\bF6\b}{\\Uf709};
                                    s{\bF7\b}{\\Uf70a};
                                    s{\bF8\b}{\\Uf70b};
                                    s{\bF9\b}{\\Uf70c};
                                    s{\bF10\b}{\\Uf70d};
                                    s{\bF11\b}{\\Uf70e};
                                    s{\bF12\b}{\\Uf70f};
                                    s{(cmd|command)[+-]}{@};
                                    s{(alt|opt(ion)?)[+-]}{~};
                                    s{shift[+-]}{\$};
                                    s{(control|ctrl)[+-]}{^};
                                    s{left}{\\U2190};
                                    s{up}{\\U2191};
                                    s{right}{\\U2192};
                                    s{down}{\\U2193};
                                    '
                        )

                        defaults write $args NSUserKeyEquivalents \
                            -dict-add "$menu_entry" "$shortcut"
                        ;;
                esac
            done
        fi
    done

    popd >/dev/null  # unnecessarily noisy
else
    error "${MACOS_SHORTCUTS_DIR} doesn't exist, cannot apply"
fi
