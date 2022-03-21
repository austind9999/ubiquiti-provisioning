#!/bin/bash

rm /tmp/ident 2>&1 > /dev/null
touch /tmp/ident
chmod 700 /tmp/ident
# Create temp config file to input SSID
cp nanostation.cfg running.cfg

# towerSSID user input field
read -p "Enter Tower SSID: " towerSSID

# Replace lines 191 and 194 in temp running.cfg file with towerSSID
sed -i "181s/.*/wpasupplicant.profile.1.network.1.ssid=$towerSSID/" running.cfg
sed -i "194s/.*/wireless.1.ssid=$towerSSID/" running.cfg

FIRMWARE=WA.v8.7.8.46705.220201.1819.bin
REMOTEIP=192.168.1.20
PASSWORD=ubnt
SSHOPTS="-q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
STEP=1
STEPS=3

# do we need to download the latest firmware?
echo "[Step 0 of $STEPS]    PREFLIGHT - searching for latest firmware version."
FWDLPATH=`curl -s -H "Accept: text/json" -H "x-requested-with: XMLHttpRequest" https://www.ui.com/download/?group=nanostation-ac | jq | grep file_path | tail -1 | awk -F":" '{print $2}' | awk -F'"' '{print $2}'`
FWNAME=`echo $FWDLPATH | awk -F"/" '{print $NF}'`
FWEXISTS=`ls -l ./$FWNAME | grep -c $FWNAME`
echo "[Step 0 of $STEPS]    PREFLIGHT - Latest version $FWNAME found from ui.com."

if [ $FWEXISTS -lt 1 ]
then
	echo "[Step 0 of $STEPS]    PREFLIGHT - $FWNAME does not exist on local disk. Downloading it now."
	curl -L -s -o $FWNAME https://www.ui.com$FWDLPATH
else
	echo "[Step 0 of $STEPS]    PREFLIGHT - $FWNAME exists on local disk. Ready to go."
fi

function waitForDevice {
	# wait for the unit to initially boot
	ONLINE=0
	while [ $ONLINE -lt 1 ]
	do
		echo "[Step $STEP of $STEPS]    Unit is still offline. Waiting for it to come up."
		ONLINE=`ping -c1 -w2 $REMOTEIP 2>&1 | grep -c "1 received"`
		sleep 1
	done
}


# wait for the unit to initially boot
waitForDevice

echo "[Step 1 of 3]    Unit is online. Beginning firmware update."
sleep 20

# update the firmware
sshpass -p$PASSWORD scp $SSHOPTS $FIRMWARE ubnt@$REMOTEIP:/tmp/fwupdate.bin 2>&1 > /dev/null
sshpass -p$PASSWORD ssh $SSHOPTS ubnt@$REMOTEIP "/sbin/fwupdate -m" 2>&1 > /dev/null
STEP=2

# wait for the unit to reboot
sleep 10
waitForDevice

echo "[Step $STEP of $STEPS]    Unit is back online, completing configuration."

sleep 10

echo "[Step $STEP of $STEPS]    Uploading UISP configuration."
sshpass -p$PASSWORD scp $SSHOPTS running.cfg ubnt@$REMOTEIP:/tmp/system.cfg 2>&1 > /dev/null
sshpass -p$PASSWORD ssh $SSHOPTS ubnt@$REMOTEIP "/sbin/cfgmtd -p /etc/ -w && /bin/sleep 5 && /usr/etc/rc.d/rc.softrestart save" 2>&1 > /dev/null
sleep 10
STEP=3


# now wait for that "soft" restart to complete
echo "[Step $STEP of $STEPS]    Waiting for unit to complete accepting new config."
waitForDevice
echo ""
echo "PROVISIONING IS COMPLETE FOR UNIT WITH TOWER SSID: $towerSSID"
