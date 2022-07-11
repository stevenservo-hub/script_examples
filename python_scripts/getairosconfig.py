#!/usr/bin/python3
import re
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import getpass
import ipaddress

#Prompts for login information
default = 'ubnt'
USERNAME = input("Enter Username: ") or default
print(USERNAME)
#using getpass to mask password.
PASSWORD = getpass.getpass("Enter Password: ")

#Bypass insecure request warning 
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

login_url = 'https://{0}/api/auth'
url_cgi = 'https://{0}/cfg.cgi',

cidr = input('Provide IP in CIDR notation: ')

# Store a list of a subnet to a variable
ip_addr = [str(ip) for ip in ipaddress.IPv4Network(cidr)]

#Removes Network and Broadcast address leavingonly usable ip's
ip_addr.pop(0)
ip_addr.pop(-1)

#Main loop
for ip in ip_addr:

    # session 
    with requests.Session() as s:

        # login 
        try:
            r = s.post(
                url=login_url.format(ip),
                data={
                'username': USERNAME,
                'password': PASSWORD, 
                },
                verify=False,
                timeout=2,
             )   
            
            #raise for error handling.
            r.raise_for_status()
       
        #Basic error handling, will also catch other devices that are in the
        #the subnet such as microtiks so that config files are not created with
        #error messages written to them, as of now im printing to the terminal
        #so you can see whats happening but these can be removed. This is kind
        #of noisy. In general this could use improvement.
        except requests.exceptions.HTTPError as errh:
            print (" Http Error:",errh)
            continue

        except requests.exceptions.ConnectionError as errc:
            print (" Error Connecting:",errc)
            continue

        except requests.exceptions.Timeout as errt:
            print ("Timeout Error:",errt)
            continue

        except requests.exceptions.RequestException as e:
            print('Unknown Error: Skipping',e)
            continue
        
        responses = {}

        #Grabs the configuration.
        for url in url_cgi:
            print('Getting config for '+ip)
            url = url.format(ip)
            r = s.get(
            url=url,
            verify=False,
            allow_redirects=True
        )
            #renames config file for unique and easy to reference config names
            url = (ip+'_backup.cfg') 

            #Writes config to file            
            open(url, 'wb').write(r.content)

exit() 
