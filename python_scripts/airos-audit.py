

import requests
import re
import json
import logging
from email.message import EmailMessage
import smtplib
from xlsxwriter import Workbook
from datetime import datetime
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(
    InsecureRequestWarning)

# base url for requests
url = 'https://192.168.89.51:9082/api/v1/'


# grab credentials from json file
json_filename = "creds.json"
with open(json_filename) as json_file:
    data = json.load(json_file)

# global variables
SENDER_EMAIL = data['emailcreds']['email']
EMAIL_PASSWORD = data['emailcreds']['password']
CREDENTIALS = data['apicreds']
LOGFILE = "/var/log/audit_script.log" 


# logging configuration
logging.basicConfig(filename=LOGFILE, level=logging.INFO,
                    format='%(levelname)s - %(message)s - %(asctime)s')
logging.info('Script execution initiated')


def send_email():  # Sends email with spreadsheet as attachment
    receivers = ['kelly@rodeotv.net', 'tac@rodeotv.net']
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    filename = f'Aircontrol_audit_{date_str}.xlsx'
    # create the message
    msg = EmailMessage()
    msg['Subject'] = "Weekly Audit"
    msg['From'] = SENDER_EMAIL
    msg['To'] = receivers
    msg.set_content(
        "Please see the attached spreadsheet containing all customers in AirControl.")
    # attach the file
    with open(filename, 'rb') as f:
        file_data = f.read()
    msg.add_attachment(file_data, maintype="application",
                       subtype="xlsx", filename=filename)
    # send email
    with smtplib.SMTP_SSL('mail.rodeotv.net', 465) as smtp:
        try:
            smtp.login(SENDER_EMAIL, EMAIL_PASSWORD)
            smtp.send_message(msg)
        except smtplib.SMTPAuthenticationError:
            logging.error('Email authentication failed')
            exit()
        except smtplib.SMTPConnectError:
            logging.error('Could not establish connection with mail server, retry running script')
            exit()
        except smtplib.SMTPDataError:
            logging.error('Data format of message rejected by server, check spreadsheet format')
            exit()


def dict_to_spreadsheet(customers):
    now = datetime.now()
    # column names must be the same as dict keys
    field_names = ['ip_address', 'name', 'address',
                   'download_speed', 'tier', 'service_status']
    date_str = now.strftime("%Y-%m-%d")
    wb = Workbook(f'Aircontrol_audit_{date_str}.xlsx')
    ws = wb.add_worksheet(f'Audit from {date_str}')
    first_row = 0
    for header in field_names:
        col = field_names.index(header)
        ws.write(first_row, col, header)
    row = 1
    for customer in customers:
        for _key, _value in customer.items():
            col = field_names.index(_key)
            ws.write(row, col, _value)
        row += 1  # enter the next row
    wb.close()


def determine_tier(download_speed):
    if download_speed < 8192:
        return "BELOW TIER 1"
    elif download_speed >= 8192 and download_speed < 16384:
        return "Tier 1"
    elif download_speed >= 16384 and download_speed < 20480:
        return "Tier 2"
    elif download_speed >= 20480:
        return "Tier 3"
    else:
        return "Tier Unknown - Fix"


def extract_datapoints(config):
    ip_re = re.compile("netconf.3.ip")
    download_re = re.compile("tshaper.2.output.rate")
    name_re = re.compile("snmp.contact")
    lan_re = re.compile("netconf.2.up")
    address_re = re.compile("snmp.location")
    found_ip = list(filter(ip_re.match, config))
    found_download = list(filter(download_re.match, config))
    found_address = list(filter(address_re.match, config))
    found_lan = list(filter(lan_re.match, config))
    found_name = list(filter(name_re.match, config))
    if found_download and found_name and found_ip:  # to grab only CPE not nodes - nodes have different config key value pairs
        datapoints = {
            'ip_address': found_ip[0].split('=')[1],
            'name': found_name[0].split('=')[1],
            'address': found_address[0].split('=')[1],
            'download_speed': int(found_download[0].split('=')[1]),
            'tier': determine_tier(int(found_download[0].split('=')[1])),
            'service_status': found_lan[0].split('=')[1],
        }
        return datapoints
    else: # if it is a node we don't want anything returned, we also don't want NoneType sent back
        return


def get_config_data(device_id):
    with requests.Session() as s:
        try:
            r = s.post(  # logs in to the radio
                url=f'{url}login',
                json=CREDENTIALS,
                verify=False,
                timeout=5,
                allow_redirects=True
            )
            r = s.get(  # gets configuration file for radio
                url=f'{url}devices/{device_id}/config',
                verify=False,
                timeout=5,
            )
        except requests.ReadTimeout:
            logging.error(
                'Credentials successful on first attempt but not second, check connection.')
            exit()

        return r.content.decode().split("\n")


def get_devices_ids():
    device_ids = []
    with requests.Session() as s:
        try:
            s.post(  # logs in to the radio
                url=f'{url}login',
                json=CREDENTIALS,
                verify=False,
                timeout=5,
                allow_redirects=True
            )

            r = s.get(  # gets configuration file for radio
                url=f'{url}devices',
                verify=False,
                timeout=5,
            )
        except requests.ReadTimeout:
            logging.error('API Credentials Incorrect or Server is down')
            exit()

    results = r.json()
    results = results['results']
    for result in results:
        device_ids.append(result['deviceId'])
        result['deviceId']
    return device_ids


devices = get_devices_ids()
logging.info('List of devices received from server')
customers = []
for device in devices:
    config = get_config_data(device)
    customer = extract_datapoints(config)
    if customer:
        customers.append(customer)
logging.info('all customer information extracted from config files')
dict_to_spreadsheet(customers)
logging.info('spreadsheet successfully created')
send_email()
logging.info('email sent successfully')
