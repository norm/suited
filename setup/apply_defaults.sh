local dir="${MACOS_DEFAULTS_DIR:=${HOME}/etc/macos/defaults}"

if [ -d $dir ]; then
    pushd $dir >/dev/null  # unnecessarily noisy

    for file in *; do
        if [ "$file" != "README.markdown" -a \
          "$file" != "README.md" -a "$file" != "LICENCE" ]; then
            status "apply $file"

            for line in $( cat "$file" ); do
                # trim whitespace
                line=$( echo "$line" | sed -e 's/^ *//' -e 's/ *$//' )

                case "$line" in
                    \#*) ;;  # ignore commented lines

                    KILL*)
                        kill=$( echo $line | cut -c6- )
                        killall $kill
                        ;;

                    *)
                        eval defaults write "$file" "$line"
                        ;;
                esac
            done
        fi
    done

    popd >/dev/null  # unnecessarily noisy
else
    error "${MACOS_DEFAULTS_DIR} doesn't exist, cannot apply"
fi
