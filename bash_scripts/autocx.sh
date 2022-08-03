#!/bin/bash

# This script is designed to add customers to an asterisk sip server
# You will want to check you use the same file stucture we do or 
# or make needed changes to the mk_files and build_config functions

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

#This function checks the current user to ensure root
root_check() {
if [ "$EUID" -ne 0 ]
then echo "Please run as root"
exit
fi
}

# Print usage statement, to guide users
print_usage() {
printf "Usage: `basename` -p <number> -l <lastname> \n you will be prompted 
to add a password, this is the clients sip secret. " #Todo, add usage 
}

# Add flags needed to build sip config
options() {
TEMP=`getopt --long -o "p:l:" "$@"`
eval set -- "$TEMP"
while true ; do
    case "$1" in

        -p )
	    phone=$2
            shift 2
        ;;
        -l )
	    last=$2
            shift 2
        ;;
        *)
          print_usage # This can be handled better
        ;;
    esac 
done;
if [ $(( $# - $OPTIND )) -lt 1 ];then
    echo "Usage: `basename` -p <number> -l <lastname>"
    exit 1
fi
# Take in client secret adding some fancy bits and the ability to backspace
password=''
echo "please enter sip users secret:\n(this is used to authenticate user to the sip server)"
while IFS= read -r -s -n1 char; do
  [[ -z $char ]] && { printf '\n'; break; } # ENTER pressed; output \n and break.
  if [[ $char == $'\x7f' ]]; then # backspace was pressed
      # Remove last char from output variable.
      [[ -n $password ]] && password=${password%?}
      # Erase '*' to the left.
      printf '\b \b' 
  else
    # Add typed char to output variable.
    password+=$char
    # Print '*' in its stead.
    printf '*'
  fi
done
}

# build file system just a rough draft need to add a more elegant apr oach
mk_files() {
sip_dir=/etc/asterisk/customer/"$last"
root_check	
mkdir "$sip_dir"
touch "$sip_dir"/sip.conf && touch "$sip_dir"/extensions.conf 
chown -r asterisk:asterisk "$sip_dir"
if [ ! -f "$sip_dir" ]; then
	echo "error creating directory: $sip_dir does not exist"
	exit 1
fi
}
# Building the config files  	
build_config() {
	{    # Needs overhaul. This is quickest way to get it up and going
		echo "[$last]"
		echo "type=friend"
		echo "context=$last-out"
		echo "username=$last"
		echo "secret=$password"
		echo "callerid=\"$last\" <$phone>"
		echo "host=dynamic"
		echo "dtmfmode=auto"
		echo "progressinband=yes"
		echo "canreinvite=no"
		echo "nat=yes"
		echo "qualify=yes"
		
	} >> "$sip_dir"/sip.conf
	{
		echo "[default]"
		echo ";;; $last"
		echo "exten => $phone,1,Dial(SIP/$last,60)"
		echo "same => n,Hangup()"
		echo ""
		echo "[$last]"
		echo "exten => _1NXXXXXXXXX,1,Set(CALLERID(all)=\"$last\" <$phone>)"
		echo "same => n,Dial(SIP/65057962*\${EXTEN}@flowroute)"
		echo "same => n,Hangup()"
	} >> "$sip_dir"/extensions.conf
echo "#include customers/$last/extensions.conf" >> "$sip_dir"/extensions.conf
echo "#include customers/$last/sip.conf" >> "$sip_dir"/sip.conf
}

options
mk_files
build_config

exit
