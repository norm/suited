local dir="${MACOS_DEFAULTS_DIR:=${HOME}/etc/macos/defaults}"

if [ -d $dir ]; then
    pushd $dir >/dev/null  # unnecessarily noisy

    for file in *; do
        # fairly standard files in a repo that aren't defaults files
        [ "$file" == 'README.markdown' ] && continue
        [ "$file" == 'README.md' ]       && continue
        [ "$file" == 'README.rst' ]      && continue
        [ "$file" == 'LICENCE' ]         && continue
        [ "$file" == 'LICENSE' ]         && continue

        # otherwise...
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
    done

    popd >/dev/null  # unnecessarily noisy
else
    error "${MACOS_DEFAULTS_DIR} doesn't exist, cannot apply"
fi
