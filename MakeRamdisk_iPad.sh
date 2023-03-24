#!/bin/sh

#  MakeRamdisk.sh
#
#
#  Created by Brayan Ivan Villa Claudio on 23/02/23.
#

uno=$1

dos="15.5"

shsh=$2


case "$uno" in
    "")
        echo "[*] PRODUCT TYPE  MISSING!"
        echo "[+] TYPE ./MakeRamdisk.sh --help"
        exit
    ;;
    "--help")
        echo "[+] TYPE ./MakeRamdisk.sh [PRODUCT TYPE] [CPID]"
        echo "[+] EXAMPLE: ./MakeRamdisk.sh iPhone10,3 0x8015"
        exit
    ;;
    "--help-boot")
        echo "[+] TYPE ./MakeRamdisk.sh [FOLDER WITH IMG4 FILES]"
        echo "[+] EXAMPLE: ./MakeRamdisk.sh boot iPhone10,3"
        exit
    ;;
    "boot")
        if [[ "$2" == "" ]]
        then
            echo "[*] FOLDER MISSING!"
            echo "[+] TYPE ./MakeRamdisk.sh --help-boot"
            exit
        fi
        source func.pb

        if [[ "$(required/irecovery -q | grep -w MODE | sed 's/MODE: //g')" == "DFU" ]]
        then
                required/gaster pwn
                required/gaster reset
        fi
        
        ircv_send_raw_file "$2/iBSS.img4"

        if [[ "$(required/irecovery -q)" == "ERROR: Unable to connect to device" ]]
        then
            echo "FAILED BOOT DEVICE! TRY AGAIN!"
            exit
        fi
        
        ircv_send_raw_file "$2/iBEC.img4"
            
        ircv_send_command "go"
        
       # ircv_send_raw_file "$2/logo.img4"

        #ircv_send_command "setpicture 0"

        #ircv_send_command "bgcolor 0 0 0"
        
        ircv_send_raw_file "$2/devicetree.img4"

        ircv_send_command "devicetree"
        
        ircv_send_raw_file "$2/ramdisk.img4"

        ircv_send_command "ramdisk"

        ircv_send_raw_file "$2/trustcache.img4"

        ircv_send_command "firmware"
        
        ircv_send_raw_file "$2/kernelcache.img4"

        ircv_send_command "bootx"
        
        exit
    ;;
esac

case "" in
    "$shsh")
        echo "[*] CPID MISSING!"
        echo "[+] TYPE ./MakeRamdisk.sh --help"
        exit
    ;;
esac



rm -rf work "$1"

mkdir -p work "$1"

xattr -s -c ./*
chmod -R 777 ./*

dirBIN="../required"
ircv_info(){
        required/irecovery -q | grep -w $1 | sed 's/'$1': //g'
}

URL="$(curl -sL "https://api.ipsw.me/v4/device/$uno?type=ipsw" | required/jq '.firmwares | .[] | select(.version=="'$dos'")' | required/jq -s '.[0] | .url' --raw-output)"

_Down(){
	cd work
	if [ "$2" != "" ]
	then
		_fileName="$(echo $1 | sed 's/'$2'//g' | sed 's/'$3'//g')";
		../required/pzb -g "$_fileName" "$URL";
	else
		../required/pzb -g "$1" "$URL";
	fi
	cd ..
}

_MakeiBEC(){
	chc=$(cat .shsh);
	if [ "$chc" != "0x8010" ] ||  [ "$chc" != "0x8015" ] ||  [ "$chc" != "0x8011" ] ||  [ "$chc" != "0x8012" ];
	then
		echo true;
	else
		echo false;
	fi
}

_iBootP(){
	if [ "$3" != "" ]
	then
		required/iBoot64Patcher -p "$2/$1.dec" "$2/$1.patched" -b "$3" $4
	else
		required/iBoot64Patcher -p "$2/$1.dec" "$2/$1.patched"
	fi
}


_MakeIMG4(){
	if [ "$1" == "ram" ]
	then
			required/img4 -i work/"$1".dmg -o sshramdisk/ramdisk.img4 -M work/IM4M -A -T "$2"
	else
	if [ "$2" != "" ]
	then
		required/img4 -i work/"$1".patched -o sshramdisk/"$1".img4 -M work/IM4M -A -T $2 $3 $4
	else
		required/img4 -i work/"$1".patched -o sshramdisk/"$1".img4 -M work/IM4M -A -T "$1"
	fi
	fi
}

_FileDown(){

	cat work/BuildManifest.plist | grep "$1" &>.plist.plist
	
	/usr/bin/plutil -convert xml1 .plist.plist
	
	cat .plist.plist | grep '<string>' | sed 's/<string>//g' | sed 's/<\/string>//g'
	
}

decrypt_File(){

	required/gaster decrypt "$1" "$2"

}

iboot_patch(){

	required/iBoot64Patcher "$1".dec "$1".patched "$2" "$3"
	
}

MakeIMG4(){
	required/img4 -i $1 -o $2 $3 $4 $5 $6 $7 $8
}

download_File(){
	cd work;
	if [[ "$(ls BuildManifest.plist)" != "BuildManifest.plist" ]]
	then
		"$dirBIN"/pzb -g "BuildManifest.plist" "$URL"
	fi
	if [[ "$2" != "" ]]
	then
		if [[ "$2" != "trustcache" ]]
		then
			"$dirBIN"/pzb -g "$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)" "$URL"
		else
			"$dirBIN"/pzb -g Firmware/"$(/usr/bin/plutil -extract "BuildIdentities".0."Manifest"."RestoreRamDisk"."Info"."Path" xml1 -o - BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | head -1)".trustcache "$URL"
		fi
	else
        "$dirBIN"/pzb -g "$(awk "/""${replace}""/{x=1}x&&/$1[.]/{print;exit}" BuildManifest.plist | grep '<string>' |cut -d\> -f2 |cut -d\< -f1 | sed 's/b//g')" "$URL"
	fi
	cd ..
}


curl -s "https://www.theiphonewiki.com/wiki/Firmware_Keys/15.x" | grep "$dos" | grep "$uno" | awk '{printf $2" "}' | awk '{printf $1}' | sed 's/href="/"https:\/\/www.theiphonewiki.com/g' &>.url

IV_IBEC="$(/usr/bin/curl -s $(printf $(cat .url) | sed 's/"//g')  | grep '<code id="keypage-ibec-iv">' | sed 's/<ul><li><b>IV<\/b>: <code id="keypage-ibec-iv">//g' | sed 's/<\/code><\/li>//g')"

KEY_IBEC="$(/usr/bin/curl -s $(printf $(cat .url) | sed 's/"//g') | grep '<li><b>Key</b>: <code id="keypage-ibec-key">' | sed 's/<li><b>Key<\/b>: <code id="keypage-ibec-key">//g' | sed 's/<\/ul><h2><span class="mw-headline" id="ISP">ISP<\/span><\/h2>//g' | sed 's/<\/code><\/li>//g' | awk '{printf $1}' | sed 's/<\/ul><h2><span//g')"


IV_IBSS="$(/usr/bin/curl -s $(printf $(cat .url) | sed 's/"//g')  | grep '<code id="keypage-ibss-iv">' | sed 's/<ul><li><b>IV<\/b>: <code id="keypage-ibss-iv">//g' | sed 's/<\/code><\/li>//g')"

KEY_IBSS="$(/usr/bin/curl -s $(printf $(cat .url) | sed 's/"//g') | grep '<li><b>Key</b>: <code id="keypage-ibss-key">' | sed 's/<li><b>Key<\/b>: <code id="keypage-ibss-key">//g' | sed 's/<\/ul><h2><span class="mw-headline" id="ISP">ISP<\/span><\/h2>//g' | sed 's/<\/code><\/li>//g' | awk '{printf $1}' | sed 's/<\/ul><h2><span//g')"
clear;

ibssKey="$IV_IBSS$KEY_IBSS"
ibecKey="$IV_IBEC$KEY_IBEC"


_Down "BuildManifest.plist"

echo "===== MAKING IM4M WITH SHSH BLOB! =====";

echo $shsh &>.shsh

required/img4tool -e -s shsh/"$shsh".shsh -m work/IM4M;


download_File "iBSS"

download_File "iBEC"

echo "===== DECRYPTING iBSS AND iBEC =====";

if [ "$(_MakeiBEC $shsh)" != "false" ];
then
	required/img4 -i work/iBEC*.im4p -o work/iBEC.dec -k "$ibecKey";
fi

required/img4 -i work/iBSS*.im4p -o work/iBSS.dec -k "$ibssKey";

if [ "$CPID" = '0x8010' ] || [ "$CPID" = '0x8015' ] || [ "$CPID" = '0x8011' ] || [ "$CPID" = '0x8012' ]
then
	required/iBoot64Patcher work/iBSS.dec work/iBSS.patched -b "rd=md0 debug=0x2014e -v wdt=-1 `if [ "$shsh" = '0x8960' ] || [ "$shsh" = '0x7000' ] || [ "$shsh" = '0x7001' ]; then echo "-restore"; fi`" -n
else
	required/iBoot64Patcher work/iBSS.dec work/iBSS.patched
fi

required/img4 -i work/iBSS.patched -o "$1"/iBSS.img4 -M work/IM4M -A -T ibss


required/iBoot64Patcher work/iBEC.dec work/iBEC.patched -b "rd=md0 debug=0x2014e -v wdt=-1 `if [ "$shsh" = '0x8960' ] || [ "$shsh" = '0x7000' ] || [ "$shsh" = '0x7001' ]; then echo "-restore"; fi`" -n
required/img4 -i work/iBEC.patched -o "$1"/iBEC.img4 -M work/IM4M -A -T ibec
	
	

download_File "DeviceTree"
find work -iname DeviceTree\*.im4p &>.dtree
Dtree=$(cat .dtree)
required/img4 -i $Dtree -o "$1"/devicetree.img4 -M work/IM4M -T rdtr


download_File "kernelcache.release"
find work -iname kernelcache.release\* &>.rkrn
Rkr=$(cat .rkrn)
required/img4 -i $Rkr -o "work/kcache.raw"
required/Kernel64Patcher work/kcache.raw work/kcache.patched -a
required/kerneldiff work/kcache.raw work/kcache.patched work/kc.bpatch
required/img4 -i $Rkr -o "$1"/kernelcache.img4 -M work/IM4M -T rkrn -P work/kc.bpatch

download_File "trustcache" "trustcache"
find work -iname \*.trustcache &>.trs
trs=$(cat .trs)
required/img4 -i $trs -o "$1"/trustcache.img4 -M work/IM4M -T rtsc

download_File "RestoreRamDisk" "RestoreRamDisk"
required/img4 -i $(find work/ -iname \*.dmg) -o "work/ramdisk.dmg"
hdiutil resize -size 300MB work/ramdisk.dmg
hdiutil attach -mountpoint SSHRD work/ramdisk.dmg
required/gtar -x --no-overwrite-dir -f other/ssh.tar -C ./SSHRD/
sleep 5
hdiutil detach -force SSHRD
hdiutil resize -sectors min work/ramdisk.dmg
required/img4 -i work/ramdisk.dmg -o "$1"/ramdisk.img4 -M work/IM4M -A -T rdsk

required/img4tool -c "$uno"/logo.img4 -p other/logo.im4p -s shsh/"$shsh".shsh

rm -rf work

