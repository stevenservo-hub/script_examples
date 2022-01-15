#!/usr/bin/bash

ifconfig | grep "broadcast" | cut -d " " -f 10 | cut -d "." -f 1,2,3 | uniq > octets.txt

OCTETS=$(cat octets.txt)

echo "" > $OCTETS.txt

for ip in {1..254}
do
       ping -c 1 $OCTETS.$ip | grep "64 bytes" | cut -d " " -f 4 | tr -d ":" >> $OCTETS.txt &
done

cat $OCTETS.txt | sort > sorted_$OCTETS.txt

nmap -sS 20 -iL sorted_$OCTETS.txt
exit
