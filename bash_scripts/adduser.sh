#!/usr/bin/bash

E_NOTROOT=87 # Non-root exit error.
# Run as root, of course.

add_user()
{

	read -p "username: " USER
	read -p "password: " PASSWORD
	shift; shift;
	read -p "add comments: " COMMENTS
	read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	echo "Adding the user $USER.."
	useradd -c "$COMMENTS" $USER
	echo -e "$PASSWORD\n$PASSWORD" | passwd $USER
	echo "Added user $USER with password $PASSWORD"
	read -p "Would you like to give the user SUDO access? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
	usermod -aG sudo $USER
}

echo "script started.."
if [ "$UID" -ne "$ROOT_UID" ]
then
echo "Must be root to run this script."
exit $E_NOTROOT
fi
add_user
