import re
import time
import socket
import random
import smtplib
from email.mime.text import MIMEText

dnsbls = '''
b.barracudacentral.org
bl.deadbeef.com
bl.emailbasura.org
bl.spamcannibal.org
bl.spamcop.net
blackholes.five-ten-sg.com
blacklist.woody.ch
bogons.cymru.com
cbl.abuseat.org
cdl.anti-spam.org.cn
combined.abuse.ch
combined.rbl.msrbl.net
db.wpbl.info
dnsbl-1.uceprotect.net
dnsbl-2.uceprotect.net
dnsbl-3.uceprotect.net
dnsbl.cyberlogic.net
dnsbl.inps.de
dnsbl.njabl.org
dnsbl.sorbs.net
drone.abuse.ch
drone.abuse.ch
duinv.aupads.org
dul.dnsbl.sorbs.net
dul.ru
dyna.spamrats.com
dynip.rothen.com
http.dnsbl.sorbs.net
images.rbl.msrbl.net
ips.backscatterer.org
ix.dnsbl.manitu.net
korea.services.net
misc.dnsbl.sorbs.net
noptr.spamrats.com
ohps.dnsbl.net.au
omrs.dnsbl.net.au
orvedb.aupads.org
osps.dnsbl.net.au
osrs.dnsbl.net.au
owfs.dnsbl.net.au
owps.dnsbl.net.au
pbl.spamhaus.org
phishing.rbl.msrbl.net
probes.dnsbl.net.au
proxy.bl.gweep.ca
proxy.block.transip.nl
psbl.surriel.com
rbl.interserver.net
rdts.dnsbl.net.au
relays.bl.gweep.ca
relays.bl.kundenserver.de
relays.nether.net
residential.block.transip.nl
ricn.dnsbl.net.au
rmst.dnsbl.net.au
sbl.spamhaus.org
short.rbl.jp
smtp.dnsbl.sorbs.net
socks.dnsbl.sorbs.net
spam.abuse.ch
spam.dnsbl.sorbs.net
spam.rbl.msrbl.net
spam.spamrats.com
spamlist.or.kr
spamrbl.imp.ch
t3direct.dnsbl.net.au
tor.dnsbl.sectoor.de
torserver.tor.dnsbl.sectoor.de
ubl.lashback.com
ubl.unsubscore.com
virbl.bit.nl
virus.rbl.jp
virus.rbl.msrbl.net
web.dnsbl.sorbs.net
wormrbl.imp.ch
xbl.spamhaus.org
zen.spamhaus.org
zombie.dnsbl.sorbs.net
'''.split()  # 6 single-quotes are better than 156


def ip2rdns(ip):
    """ Reverse IP for use with DNS Lookups. """
    octets = '\.'.join(['(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'] * 4)
    match = re.search(r'\b{}\b'.format(octets), ip)
    return '.'.join([match.group(i) for i in reversed(range(1, 5))])  # 4, 3, 2, 1


def alert(ip, bl):
    email_from = email['from_address']
    email_to = email['to_address']
    email_subject = '{} detected on DNS Blacklists'.format(ip)
    email_body = '\n'.join([
        'Please be advised that {} has detected '.format(ip),
        'itself on DNS Blacklists:\n',
        '\n'.join([x for x in bl]),
        '\n{}'.format(email['signature'])
    ])
    msg = MIMEText(email_body)
    msg['Subject'] = email_subject
    msg['From'] = email_from
    msg['To'] = email_to
    smtp = smtplib.SMTP(email['server'])
    smtp.sendmail(email_from, [email_to], msg.as_string())
    smtp.quit()


if __name__ == '__main__':
    email = {
        'server': 'backupemailserver.domain.com',
        'to_address': 'operations@domain.com',
        'from_address': 'alerts@monitoring.com',
        'signature': 'Sincerely, Monitoring System'
    }
    servers = {
        '203.102.137.35',
        '203.166.101.145',
        '203.102.137.234'
    }
    for server in servers:
        flagged_lists = set()
        for blacklist in dnsbls:
            rdns = '{}.{}'.format(ip2rdns(server), blacklist)
            try:
                listed = bool(socket.gethostbyname(rdns))
            except socket.gaierror:
                listed = False
            if listed:
                flagged_lists.add(blacklist)
        alert(server, flagged_lists)
    time.sleep(random.randint(300, 14400))
