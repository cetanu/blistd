import os
import re
import time
import socket
import random
import smtplib
from urllib import request
from datetime import datetime as dt
from email.mime.text import MIMEText


class Blistd (object):
    def __init__(self, settings):
        self.dnsbl = self._update()
        self.email = settings

    def _update(self):
        """ Download a list of DNSBLs from public gist """
        print("Updating DNSBLs")
        url = self._findgist()
        gist = request.urlopen("https://gist.github.com{}".format(url))
        dnsbls = (dnsbl.decode("utf-8").rstrip("\n") for dnsbl in gist)
        return dnsbls

    @staticmethod
    def _findgist():
        url = request.urlopen('https://gist.github.com/cetanu/9697771')
        for line in url.readlines():
            match = re.search(r'=\"(.*?raw.*?)\"', str(line))
            if match is not None:
                return match.groups()[0]

    def check(self, ip):
        """ Perform a DNS lookup. If it fails, we're in the clear! """
        blacklisted = list()
        for bl in self.dnsbl:
            rdns = "{}.{}".format(self._reverse_ip(ip), bl)
            try:
                socket.gethostbyname(rdns)
                self._log("{} - BLACKLISTED: {}".format(ip, bl))
                # Collect a list of blacklists before emailing
                blacklisted.append(bl)
            except socket.gaierror:
                print("{} - OK: {}".format(ip, bl))
        if len(blacklisted):
            self._alert(ip, blacklisted)

    def _alert(self, ip, bl):
        """ Email alerting """
        email_from = self.email['from_address']
        email_to = self.email['to_address']
        email_subject = "{} detected on DNS Blacklists".format(ip)
        email_body = '\n'.join(
            [
                "Please be advised that {} has detected ".format(ip),
                "itself on DNS Blacklists:\n",
                '\n'.join([x for x in bl]),
                "\n{}".format(self.email['signature'])
            ]
        )
        msg = MIMEText(email_body)
        msg['Subject'] = email_subject
        msg['From'] = email_from
        msg['To'] = email_to
        try:
            smtp = smtplib.SMTP(self.email['server'])
            smtp.sendmail(email_from, [email_to], msg.as_string())
            smtp.quit()
            print("{} - EMAIL SENT".format(ip))
        except socket.error:
            self._log("{} - EMAIL FAILED".format(ip))

    def sleep(self):
        """ After work is done, rest for a while to avoid getting b& """
        sleep = random.randint(300, 14400)
        self._log("Sleeping for {} minutes...".format(sleep/60))
        time.sleep(sleep)

    @staticmethod
    def _log(string):
        """ Write to console and file with datetime """
        print(string)
        with open('blistd.log', 'a') as logfile:
            logfile.write("{} | {}\n".format(str(dt.now()), string))

    @staticmethod
    def _reverse_ip(ip):
        """ Reverse IP for use with DNS Lookups. """
        octets = "\.".join(["(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"] * 4)
        match = re.search(r'\b{}\b'.format(octets), ip)
        return '.'.join([match.group(i) for i in reversed(range(1, 5))])  # 4, 3, 2, 1


if __name__ == '__main__':
    blistd = Blistd(
        {
            'server': 'mail.domain.com',
            'to_address': 'operations@domain.com',
            'from_address': 'alerts@monitoring.com',
            'signature': 'Sincerely, Monitoring System'
        }
    )
    servers = [
        "203.102.137.35",
        "203.166.101.145",
        "203.102.137.234"
    ]
    while True:
        for server in servers:
            blistd.check(server)
        blistd.sleep()
