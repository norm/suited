The Dockfile
============

The `Dockfile` is used to control the contents of the Dock. It uses
`dockutil`, which will be installed with homebrew (if it is not already).

Lines starting with a hash (`#`) are comments and will be ignored.

## `add`

A line starting `add` will add an icon to the Dock.

    # assumed to be /Applications/Things.app
    add Things

    # quote applications with spaces in the name
    add 'Sublime Text'

    # control where it is added
    add Things after Launchpad
    add nvALT before Things

    # add an application from elsewhere
    add /Applications/Utilities/Terminal.app

Adding apps from unusual locations will cause an error when the app already
exists in the Dock:

    Terminal already exists in dock. Use --replacing 'Terminal' to update an existing item
    item /Applications/Utilities/Terminal.app was not added to Dock

This can be silenced by providing the name of the app as the fifth argument:

    add /Applications/Utilities/Terminal.app after Launchpad Terminal


## `remove`

A line starting `remove` will remove an icon from the Dock.

    remove Contacts

    # quote applications with spaces in the name
    remove 'Sublime Text'
