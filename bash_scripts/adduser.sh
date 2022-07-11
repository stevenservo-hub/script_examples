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
	echo -e "$PASSWORD\n$PASSWORD" | sudo passwd $USER
	echo "Added user $USER with password $PASSWORD"
	read -p "Would you like to give the user SUDO access? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	sudo usermod -a -G sudo $USER
}
echo "script started.."
add_user
