#!/bin/bash

# This script is designed to add customers to an asterisk sip server
# You will want to check you use the same file stucture we do or 
# or make needed changes to the mk_files and build_config functions

# exit when any command fails
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command returned exit code $?."' EXIT

#This function checks the current user to ensure root
root_check() {
if [ "$EUID" -ne 0 ]
then echo "Please run as root"
exit
fi
}

# Print usage statement, to guide users
print_usage() {
printf "Usage: autocx -phone '5555555555' -last 'lastname'\n" #Todo, add usage 
}

# Prompt user for input, only if flags are not provided
prompt_info() {
read -p 'Please provide users assigned phone number (no dashes i.e 5095550155): ' phone
read -p 'Users lastname: ' last
}

#Prompt user for sip secret.
sip_secret() {
password=''
echo "please enter sip users secret:"
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
sip_dir=/etc/asterisk/customers/"$last"
root_check	
mkdir "$sip_dir" # It occured to me there could be multiple users with the same last name. This has been tested, as long as set -e
                 # remains it will exit as "directory exists" instead of overwriting, but maybe this should be explicitly handled
touch "$sip_dir"/sip.conf && touch "$sip_dir"/extensions.conf 
chown -R asterisk:asterisk "$sip_dir"
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
		echo "same => n,Dial(SIP/00000000*\${EXTEN}@flowroute)"
		echo "same => n,Hangup()"
	} >> "$sip_dir"/extensions.conf
echo "#include customers/$last/extensions.conf" >> /etc/asterisk/customers/extensions.conf
echo "#include customers/$last/sip.conf" >> /etc/asterisk/customers/sip.conf
}

# Added flags for convenience sake, if left blank (or not complete) whoever runs the script will be prompted instead
while test $# -gt 0; do
           case "$1" in
		-phone)
                    shift
		    phone=$1
                    shift
                    ;;
                -last)
                    shift
                    last=$1
                    shift
                    ;;
                -h)
		    print_usage
		    exit 1;
                    ;;
                --help)
		    print_usage
		    exit 1;
                    ;;
                *)
                   echo "$1 is not a recognized flag!"
		   print_usage
                   exit 1;
                   ;;
          esac
done  

# If flags are not used we will prompt the user for the needed info
if [[ -z $phone ]] || [[ -z $last ]];
then prompt_info
fi

#ADD regex to test for number format HERE

sip_secret
mk_files
build_config

printf "Build complete!\n"

exit
