Prolog tests whether the script has been invoked with the correct number of parameters:

E_WRONG_ARGS=85
script_parameters="-a -h -m -z"
# -a = all, -h = help, etc.
if [ $# -ne $Number_of_expected_args ]
then
echo "Usage: `basename $0` $script_parameters"
# `basename $0` is the script's filename.
exit $E_WRONG_ARGS
fi


calculating script run-time:

Add this to the beginning of the script:

    START=$(date +%s)

Add following at the end or exit location:

    END=$(date +%s)
    DIFF=$(( $END - $START ))
    DIFF=$(( $DIFF / 60 ))

$DIFF will give you the runtime of the script in minutes.



Parsing & processing script parameters / arguments:

    while [ "$1" != "" ]; do
        case $1 in
            -s  )   shift	
    		SERVER=$1 ;;  
            -d  )   shift
    		DATE=$1 ;;
    	--paramter|p ) shift
    		PARAMETER=$1;;
            -h|help  )   usage # function call
                    exit ;;
            * )     usage # All other parameters
                    exit 1
        esac
        shift
    done

Above snippet in shell script paramter_test.sh will behave as follows:

    sh parameter_test.sh -s myserver -d 20151225 --parameter SomeValue

Though we may need to check for correctness of input or mandatory parameters; using say a parser function.
# Confirm the mandatory parameters

    if [ -z $SERVER ] || [ -z $DATE ]; then
    	echo "Please specify both server and date";
    	exit 1;
    fi;



Change directory before processing your script:


    changedir()
    {
    	DIR_NAME=$1
    	# Check if the directory exist?
    	[ -d "$DIR_NAME" ] || {
    		echo Dir: $DIR_NAME does not exist 
    		exit 1
    	}

    	# Check if the directory is readable
    	[ -r "$DIR_NAME" ] || {
    		echo Dir: $DIR_NAME not readable
    		exit 2
    	}

    	# Check if we have execute perms on directory
    	[ -x "$DIR_NAME" ] || {
    		echo Dir: cannot cd to $DIR_NAME
    		exit 3
    	}

    	# Check if the directory is writable
    	[ -w "$DIR_NAME" ] || {
    		echo Dir: $DIR_NAME not writeable
    		exit 4
    	}

    	cd $DIR_NAME
    	echo "Present directory $DIR_NAME"
    }

To safely change the directory call the function as follows:

    changedir /data/app/



    Verifying if previous command was successful

When a processing of command depends on success or failure of previous command we can use the exit status. It can be checked using $?.

    if [ $? -ne 0 ]; then
    	echo "The command was not successful.";
    	#do the needful / exit
    fi;



Generating script logs with timestamp

Just as the duration of script it’s useful to have timestampped log. Use following function to log time for every output.

    log() {
         echo [`date +%Y-%m-%d\ %H:%M:%S`] $*
    }

Call the function as follows instead of simply “echo”ing.

    log "my string to be logged"



Checking if process is running:

This code snippet is used often when a script progress requires the known status of any particular system process.
A usual scenario say we need MySQL down before progressing further in script, we will use following shell function.

    # Define shell function
    check_process() {
    	echo "Checking if process $1 exists..."
    	[ "$1" = "" ]  && return 0
    	PROCESS_NUM=$(ps -ef | grep "$1" | grep -v "grep" | wc -l)
    	if [ $PROCESS_NUM -ge 1 ];
    	then
    	        return 1
    	else
    	        return 0
    	fi
    }

# Check for MySQL process and make the decision

    check_process mysql;
    CHECK_RET=$?;
    if [ $CHECK_RET -ne 0 ]; 
    	# code block for process exists 
    else
    	# code block for process not present
    fi;



Colouring your script output

A readable and formatted output is good to have. Following code snippet helps you beautify your script output, colorizing or highlighting them.

    Define variables:
    txtund=$(tput sgr 0 1)    # Underline
    txtbld=$(tput bold)       # Bold
    txtred=$(tput setaf 1)    # Red
    txtgrn=$(tput setaf 2)    # Green
    txtylw=$(tput setaf 3)    # Yellow
    txtblu=$(tput setaf 4)    # Blue
    txtpur=$(tput setaf 5)    # Purple
    txtcyn=$(tput setaf 6)    # Cyan
    txtwht=$(tput setaf 7)    # White
    txtrst=$(tput sgr0)       # Text reset

    Use them as:
    echo "${txtbld}This is bold text output from shell script${txtrst}"
    echo "${txtred}This is coloured red except ${txtblu}this is blue${txtrst}"

    ${txtrst} will reset the terminal.

Refer: http://kedar.nitty-witty.com/blog/how-to-echo-colored-text-in-shell-script
8. Reading variables from config file

Create a config file with contents as follows:

    key1=value1
    key2=value2

Add following line in the beginning of the shell script:

    . configfile

This will load the key value pairs and you may verify & access the values as $key1 or $key2.



Looping over files in a folder

Below code snippet is quite simple as a concept of FOR loop we might need to loop over the files to perform operations.

    #!/bin/bash
    PATH=/path/to/dir/
    FILES=*.sql
    for f in $PATH$FILES
    do
    	# Code block for processing each file $f
    done

Using SWITCH…CASE

Following code snippet is a SWITCH…CASE for shell script often used for taking actions based on variable value.

    	case $VARIABLE in
    		VALUE-1) # CODE BLOCK FOR VALUE-1
    			;;

    		VALUE-2|VALUE-3) 
    			# CODE BLOCK FOR VALUE-2 OR VALUE-3
    		 	;;

    		*) echo "Wrong option, exiting.";;
    	esac

(Bonus solution to – how-to-send-email worries!)



The sendEmail Function

set is variable values for email-content ($content), email-subject ($subject) and email-list ($email_list). Rest is only making a call to the function (sendEmail).

    # sendEmail Function - mail & exit.
    START=$(date +%s)
    sendEmail() {
    	scripttime=0;
    	END=$(date +%s)
    	DIFF=$(( $END - $START ))
    	if [ $DIFF -le 60 ]; then
    		scripttime="$DIFF seconds.";
    	else
    		DIFF=$(( $DIFF / 60 ))
    		scripttime="$DIFF minutes.";
    	fi;
    	content="$content. Exec Time: $scripttime"
    	echo $content | mail -s "$subject" $email_list
    	exit;
    }
    # sendEmail Function - end.


