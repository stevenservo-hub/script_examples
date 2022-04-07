#!/usr/bin/bash

ifconfig | grep "broadcast" | cut -d " " -f 10 | cut -d "." -f 1,2,3 | uniq > octets.txt
echo "looking for active devices on the network"
cat octets.txt | while read line || [[ -n $line ]];
do
	for ip in {1..254}
	do
	ping -c 1 $line.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" >> octets.txt &
	done
done

sudo nmap -sS 20 -iL octets.txt
exit

