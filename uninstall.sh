#!/bin/sh


# Figure out the TLD for the resolver file basically a quick & dirty regex on the config.json file

    tld=`cat ./config.json | grep tld | grep -o ": \"\(.\+\)\",\$" | cut -c 4-6`

# Remove configuration files

    echo "*** Removing system configuration files as root..."
    sudo launchctl unload -Fw /Library/LaunchDaemons/davewasmer.marathon.forwarding.plist 2>/dev/null
    launchctl unload -Fw "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist" 2>/dev/null

    echo "*** Removing configuration files..."
    sudo rm "/etc/resolver/$tld"
    sudo rm /Library/LaunchDaemons/davewasmer.marathon.forwarding.plist
    rm "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"


# All done!

    echo "*** Marathon has been uninstalled"
    echo "Note: I left your projects file (~/.marathon) untouched."
