# Release checklist

To create a new release of suited create a new Github issue, copy the
checklist below into it, then complete each item.

- [ ] Create a release branch
- [ ] Check the changelog has all changes made on master actually listed;
      if not add them
- [ ] Update the changelog with the new version number
- [ ] Update `suited.sh` with the new version number
- [ ] PR/merge the release branch
- [ ] Tag the merge commit with the new version
- [ ] Checkout the `latest` branch, `git merge --ff-only master`, and push
- [ ] Close this issue as done
