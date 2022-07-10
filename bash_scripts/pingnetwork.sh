#!/usr/bin/bash
ip addr | grep "\inet\b" | cut -d " " -f 6 | cut -d "." -f 1,2,3 | uniq > octets.txt

echo "looking for active devices on the network"
cat octets.txt | while read line || [[ -n $line ]];
do
	for ip in {1..254}
	do
	ping -c 1 $line.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" >> octets.txt &
	done
done

sudo nmap -sS 20 -iL octets.txt | tee results.txt
rm octets.txt
exit

