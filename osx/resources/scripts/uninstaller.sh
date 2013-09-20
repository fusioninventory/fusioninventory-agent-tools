#!/bin/bash

OSVER=`uname -r`
echo "OSVer is $OSVER"

PID=`ps ax -e | grep /opt/fusioninventory-agent/perl/bin/perl | grep -v grep | awk '{print $1}''`
if [ "$PID" !=  "" ]; then
	echo "killing process: $PID"
	sudo kill $PID
fi

FILES="/Library/Receipts/FusionInventory-Agent* /var/lib/fusioninventory-agent/ /opt/fusioninventory-agent /var/log/fusioninventory.log"

if [ "$OSVER" == "7.9.0" ]; then
	FILES="$FILES /Library/StartupItems/FusionInventory"
else
	FILES="$FILES /Library/LaunchAgents/org.fusioninventory.agent.plist /Library/LaunchDaemons/org.fusioninventory.agent.plist"

	echo 'Stopping and unloading service'
	launchctl stop org.fusioninventory.agent
	launchctl unload /Library/LaunchDaemons/org.fusioninventory.agent.plist
fi

for FILE in $FILES; do
  echo 'removing '.$FILE
  rm -f -R $FILE
done

if [ -e ./dscl-remove-user.sh ]; then
  	sudo ./dscl-remove-user.sh
else
    echo 'Try to remove user & grou _fusioninventoy : not the case anymore since the agent runs as root, but was the case with the first versions'
  	echo 'Removing _fusioninventory from admin and daemon group'

	sudo dscl . -delete /Groups/admin GroupMembership _fusioninventory
	sudo dscl . -delete /Groups/daemon GroupMembership _fusioninventory

	echo 'Removing _fusioninventory user'

	sudo dscl . -delete /Users/_fusioninventory

	echo 'Removing _fusioninventory group'

	sudo dscl . -delete /Groups/_fusioninventory
fi
