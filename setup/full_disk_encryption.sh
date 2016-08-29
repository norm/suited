if ! fdesetup status | egrep 'FileVault is (On|Off, but will be enabled)'; then
    echo 'Enabling full-disk encryption'
    sudo fdesetup enable -user "$USER" | tee ~/Desktop/"FileVault Recovery Key.txt"
fi
