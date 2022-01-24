#!/usr/bin/bash

add_user()
{

	read -p "username: " USER
	read -p "password: " PASSWORD
	shift; shift;
	read -p "add comments: " COMMENTS
	read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	echo "Adding the user $USER.."
	sudo useradd -c "$COMMENTS" $USER
	echo passwd --stdin $USER $PASSWORD
	echo "Added user $USER with password $PASSWORD"

}
echo "script started.."
add_user
