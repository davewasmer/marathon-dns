#!/bin/sh


# Fail fast if we're not on OS X >= 10.6.0.

    if [ "$(uname -s)" != "Darwin" ]; then
      echo "Sorry, Marathon requires Mac OS X to run." >&2
      exit 1
    elif [ "$(expr "$(sw_vers -productVersion | cut -f 2 -d .)" \>= 6)" = 0 ]; then
      echo "Marathon requires Mac OS X 10.6 or later." >&2
      exit 1
    fi


# Wicked cool ASCII art

    echo "##                            _   _                 "
    echo "##  _ __ ___   __ _ _ __ __ _| |_| |__   ___  _ __  "
    echo "## | '_ \` _ \ / _\` | '__/ _\` | __| '_ \ / _ \| '_ \ "
    echo "## | | | | | | (_| | | | (_| | |_| | | | (_) | | | |"
    echo "## |_| |_| |_|\__,_|_|  \__,_|\__|_| |_|\___/|_| |_|"
    echo "##"
    echo ""


# Expand ~ in the configuration file

    echo ""
    echo "*** Expanding configuration paths ..."
    sed -i '' -e "s#~#$HOME#g" ./config.json


# Install the various plists and config files

    echo "*** Installing configuration files..."

    # install the resolve to capture requests to *.dev and forward them to our proxy port
    sudo mkdir /etc/resolver
    sudo cp ./installation/resolver "/etc/resolver/dev"

    # install the ipfw rule to capture any inbound requests on port 80 and move them to our proxy port
    # we do this so the proxy server doesn't need to run as sudo - we only need sudo once to install
    # these files
    sudo cp ./installation/davewasmer.marathon.forwarding.plist /Library/LaunchDaemons/

    # install the marathon process to start on boot and stay alive
    # this process will host the DNS to respond to domain queries on *.dev, and the proxy server
    # to farm out the actual requests to their appropriate servers (and ports)
    cp ./installation/davewasmer.marathon.marathond.plist "$HOME/Library/LaunchAgents/"

    # because the marathon process is started by launchctl and not the user, we don't have access to
    # their shell env, including PATH variables. So we need to capture that stuff now, while we can,
    # and inject it into the launchctl plists
    modulepath=`pwd`
    execpath=$modulepath"/index.js"
    nodepath=$npm_config_prefix"/bin/node"
    sed -i '' -e "s#EXEC#$execpath#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#NODE#$nodepath#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#LOG#$logs/marathon.log#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#WORKINGDIR#$modulepath#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"
    sed -i '' -e "s#PATHEXPORT#$PATH#g" "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist"

    # bring out the sudo hammer - load the installed files into launchctl
    echo "*** Installing system configuration files as root..."
    sudo launchctl load -Fw /Library/LaunchDaemons/davewasmer.marathon.forwarding.plist 2>/dev/null
    launchctl load -Fw "$HOME/Library/LaunchAgents/davewasmer.marathon.marathond.plist" 2>/dev/null


# All done!

    echo "*** Installation complete ***"

