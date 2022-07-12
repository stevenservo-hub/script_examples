#!/bin/bash
    
# backup template
function backups {
    
    if [ -z $1 ]; then
        user=$(whoami)
    else 
        if [ ! -d "/home/$1" ]; then
                echo "Requested $1 user home directory doesn't exist."
                exit 1
        fi
        user=$1
    fi 
    
    input=/home/$user
    output=/tmp/${user}_home_$(date +%Y-%m-%d_%H%M%S).tar.gz
    
    function file_count {
        find $1 -type f | wc -l
    }
    
    function directories_count {
        find $1 -type d | wc -l
    }
    
    function archived_directories_count {
        tar -tzf $1 | grep  /$ | wc -l
    }
    
    function archived_files_count {
        tar -tzf $1 | grep -v /$ | wc -l
    }
    
    tar -czf $output $input 2> /dev/null
    
    source_files=$( file_count $input )
    source_directories=$( directories_count $input )
    
    arc_files=$( archived_files_count $output )
    arc_directories=$( archived_directories_count $output )
    
    echo "user"
    echo "Files to be included: $source_files"
    echo "Directories to be included: $source_directories"
    echo "Files to be archived: $arc_files"
    echo "Directories to be archived: $arc_directories"

    if [ $source_files -eq $arc_files ]; then
        echo "backup of $input completed successfully!"
        echo "Details of backup file:"
        ls -l $output
    else
        echo "backup of $input has failed, please check and try again!"
    fi
}
    
for dir in $*; do
    backup $dir 
    let all=$all+$arc_files+$arc_directories
done;
    echo "BACKUP COMPLETE! : $all"
