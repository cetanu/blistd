#
#   ______   __       __   ______   ______  _____    
#  /\  == \ /\ \     /\ \ /\  ___\ /\__  _\/\  __-.  
#  \ \  __< \ \ \____\ \ \\ \___  \\/_/\ \/\ \ \/\ \ 
#   \ \_____\\ \_____\\ \_\\/\_____\  \ \_\ \ \____- 
#    \/_____/ \/_____/ \/_/ \/_____/   \/_/  \/____/ 
#                                                  
#          https://github.com/cetanu/blistd/blistd.py
#

from datetime import datetime as dt
from email.mime.text import MIMEText
import smtplib
import urllib2
import socket
import random
import time
import os
import re


class Blistd (object):
    def __init__(self):
        self.dnsbl = self._update()

    def check(self, ip):
        """ Perform a DNS lookup. If it fails, we're in the clear! """
        forward_ip = ip
        reverse_ip = self._reverse_ip(ip)
        for bl in self.dnsbl:
            try:
                socket.gethostbyname("{}.{}".format(reverse_ip, bl))
                self._log("{} - BLACKLISTED: {}".format(forward_ip, bl))
                self._alert(forward_ip, bl)
            except socket.gaierror:
                self._log("{} - OK: {}".format(forward_ip, bl))

    def _alert(self, ip, bl):
        """ Email settings """
        email_server = "server@email.com"
        email_from = "from@email.com"
        email_to = "to@email.com"
        email_signature = "Sincerely, Monitoring System"
        email_subject = "{} detected on {} DNS Blacklist".format(ip, bl)
        email_body = ''.join(
            [
                "Please be advised that {} has detected ".format(ip),
                "itself on DNS Blacklist: {}\n".format(bl),
                "{}".format(email_signature)
            ]
        )
        msg = MIMEText(email_body)
        msg['Subject'] = email_subject
        msg['From'] = email_from
        msg['To'] = email_to
        try:
            smtp = smtplib.SMTP(email_server)
            smtp.sendmail(email_from, [email_to], msg.as_string())
            smtp.quit()
            self._log("Email sent to {}".format(email_to))
        except socket.error:
            self._log("Failed to send email using {}".format(email_server))
            #exit() # If you want the program to close when it can't email, uncomment.

    def _reverse_ip(self, ip):
        """ Reverse IP for use with DNS Lookups.  """
        self._log("Reversing {}...".format(ip))
        octet = "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        match = re.search(r'\b{0}\.{0}\.{0}\.{0}\b'.format(octet), ip)
        return "{}.{}.{}.{}".format(
            match.group(4),
            match.group(3),
            match.group(2),
            match.group(1)
        )

    def _update(self):
        """ Download a list of DNSBLs from public gist """
        self._log("Updating DNSBLs...")
        url = urllib2.urlopen('https://gist.github.com/cetanu/9697771')
        match = ''
        for line in url.readlines():
            match = re.search(r'=\"(.*?raw.*?)\"', line)
            if match is not None:
                break
        url = urllib2.urlopen("{}{}".format('https://gist.github.com', match.groups()[0]))
        dnsbls = []
        for dnsbl in url.readlines():
            dnsbls += [dnsbl.strip("\n")]
        return dnsbls

    def sleep(self):
        """ After work is done, rest for a while to appear less robotic """
        sleep = random.randint(300, 14400)
        self._log("Sleeping for {} minutes...".format(sleep/60))
        time.sleep(sleep)

    @staticmethod
    def _log(string):
        """ Log to console and file with datetime """
        print string
        try:
            logfile = open('blistd.log', 'a')
        except IOError:
            logfile = open('blistd.log', 'w+')
        logfile.write("{} | {}\n".format(str(dt.now()), string))
        logfile.close()


blistd = Blistd()
while True:
    blistd.check("203.102.137.35")
    blistd.check("203.166.101.145")
    blistd.check("203.102.137.234")
    blistd.sleep()
