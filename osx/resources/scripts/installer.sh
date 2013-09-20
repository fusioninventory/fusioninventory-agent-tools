#!/bin/bash

PREFIX="$1/Contents/Resources"
logger -i 'determining OS Version'
OSVER=`uname -r`
logger -i "OS: $OSVER"

#echo 'Running package installer'
INSTALL_PATH="/opt/fusioninventory-agent"
echo "Copying uninstall script to $INSTALL_PATH"
sudo chmod 700 "$PREFIX/scripts/uninstaller.sh"
sudo cp "$PREFIX/scripts/uninstaller.sh" $INSTALL_PATH/
sudo cp "$PREFIX/agent.cfg" $INSTALL_PATH/
sudo cp "$PREFIX/cacert.pem" $INSTALL_PATH/
sudo cp "$PREFIX/run.sh" $INSTALL_PATH/

sudo chmod -R 755 $INSTALL_PATH

if [ "$OSVER" == "7.9.0" ]; then
	echo "Found Jaguar OS, using 10.3 StartupItems setup"
	TPATH="/System/Library/StartupItems"
	sudo cp -R "$PREFIX/launchfiles/10_3_9-startup/FusionInventory" $TPATH/
	sudo chown -R root:wheel $TPATH/FusionInventory
	sudo chmod 755 $TPATH/FusionInventory
	sudo chmod 644 $TPATH/FusionInventory/StartupParameters.plist
	sudo chmod 755 $TPATH/FusionInventory/FusionInventory

	echo 'Starting Service using Sudo'
	sudo /System/Library/StartupItems/FusionInventory/FusionInventory start
else
	echo "Found Tiger or newer OS, using LaunchDaemons plists"
	TPATH="/Library/LaunchDaemons/"
	sudo cp "$PREFIX/launchfiles/org.fusioninventory.agent.plist" $TPATH
	sudo chown root:wheel $TPATH/org.fusioninventory.agent.plist
	sudo chmod 644 $TPATH/org.fusioninventory.agent.plist

	echo 'Loading Service'
	sudo launchctl load $TPATH/org.fusioninventory.agent.plist

	echo 'Starting Service'
	sudo launchctl start org.fusioninventory.agent
fi

sudo chflags -R hidden /opt
echo 'done'
exit 0 
