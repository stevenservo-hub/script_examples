#!/usr/bin/python3
import re
import requests
from requests.packages.urllib3.exceptions import InsecureRequestWarning
import getpass
import ipaddress

def login(username, password, ip):
    login_url = 'https://{}/api/auth'.format(ip)
    with requests.Session() as s:
        try:
            r = s.post(
                url=login_url,
                data={
                    'username': username,
                    'password': password,
                },
                verify=False,
                timeout=2,
            )
            r.raise_for_status()
            return s
        except requests.exceptions.HTTPError as errh:
            print("Http Error:", errh)
        except requests.exceptions.ConnectionError as errc:
            print("Error Connecting:", errc)
        except requests.exceptions.Timeout as errt:
            print("Timeout Error:", errt)
        except requests.exceptions.RequestException as e:
            print("Unknown Error: Skipping", e)
        return None

def get_config(session, ip):
    url_cgi = 'https://{}/cfg.cgi'.format(ip)
    try:
        r = session.get(
            url=url_cgi,
            verify=False,
            allow_redirects=True
        )
        if r.status_code == 200:
            # Renames config file for unique and easy-to-reference config names
            filename = ip + '_backup.cfg'
            # Writes config to file
            open(filename, 'wb').write(r.content)
            print('Config saved for', ip)
        else:
            print('Failed to retrieve config for', ip)
    except requests.exceptions.RequestException as e:
        print('Unknown Error: Skipping', e)

# Bypass insecure request warning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

# Prompts for login information
username = input("Enter Username: ") or default
# Using getpass to mask password.
password = getpass.getpass("Enter Password: ")

# Get IP in CIDR notation
cidr = input('Provide IP in CIDR notation: ')

# Store a list of subnet IPs in a variable
ip_addr = [str(ip) for ip in ipaddress.IPv4Network(cidr)]

# Removes Network and Broadcast address leaving only usable IPs
ip_addr.pop(0)
ip_addr.pop(-1)

# Main loop
for ip in ip_addr:
    session = login(username, password, ip)
    if session:
        get_config(session, ip)

exit()
