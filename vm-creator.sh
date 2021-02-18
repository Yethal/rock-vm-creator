#!/bin/sh
set +e

FILE=roonbox-linuxx64-nuc3-usb-factoryreset.img
VM=ROCK
MEM=4096
CPUS=4
SIZE=65535
BOOT=headless
#Change boot to gui if you need to see the vm screen
echo "Creating VM"
vboxmanage createvm --name "$VM" \
  --ostype "Ubuntu (64-bit)" \
  --register >/dev/null 2>&1

echo "Preparing installer"
# download and prepare the installer
if [ ! -f install.vdi ]; then
  if [ ! -f $FILE ]; then
    if [ ! -f $FILE.gz ]; then
      echo "Downloading the installer from Roon server"
      wget -q https://download.roonlabs.com/builds/$FILE.gz
    fi
    gunzip $FILE.gz 
  fi
  vboxmanage convertfromraw $FILE install.vdi --format VDI >/dev/null 2>&1
fi

vboxmanage createmedium disk \
  --filename "$VM".vmdk \
  --size $SIZE  >/dev/null 2>&1

vboxmanage storagectl "$VM" \
  --name "SATA" \
  --add sata \
  --controller IntelAHCI \
  --bootable on \
  --hostiocache on

vboxmanage storageattach "$VM" \
  --storagectl "SATA" \
  --port 0 \
  --type hdd \
  --hotpluggable on \
  --medium install.vdi


vboxmanage storageattach "$VM" \
  --storagectl "SATA" \
  --port 1 \
  --type hdd \
  --nonrotational on \
  --discard on \
  --medium "$VM".vmdk

vboxmanage modifyvm "$VM" \
  --boot1 disk \
  --boot2 none \
  --boot3 none \
  --boot4 none \
  --memory "$MEM" \
  --cpus "$CPUS" \
  --graphicscontroller vboxvga \
  --firmware bios \
  --usbxhci on \
  --keyboard usb \
  --nic1 nat

echo "Starting installation process"
vboxmanage startvm "$VM" --type=$BOOT >/dev/null 2>&1
sleep 20
# Type through the installation menu
vboxmanage controlvm "$VM" keyboardputscancode 02 82
vboxmanage controlvm "$VM" keyboardputscancode 1c 9c
sleep 2
vboxmanage controlvm "$VM" keyboardputscancode 02 82
vboxmanage controlvm "$VM" keyboardputscancode 1c 9c
sleep 2
vboxmanage controlvm "$VM" keyboardputscancode 15 95
vboxmanage controlvm "$VM" keyboardputscancode 1c 9c
sleep 30
#detach installer from vm
vboxmanage storageattach "$VM" \
  --storagectl "SATA" \
  --port 0 \
  --device 0 \
  --type hdd \
  --medium none

rm install.vdi
rm $FILE
vboxmanage controlvm "$VM" poweroff >/dev/null 2>&1
echo "Installation complete"
echo "You can now move the $VM.vmdk virtual disk file to the destination server"
