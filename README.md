# blistd <sup>DNS Blacklist Lookup</sup>

---

## About

This is a Powershell script which checks each DNS Blacklist to see if your IP has been listed.  

## Features

- Randomized wait between executions so that we don't look like robots to the DNSBL hosts
- Email alerting via SMTP
- Logging

## How to use this thing

1. Simply download the script
3. Change the IP and Email settings to whatever is appropriate for your environment
3. Run the script
7. Done

## Contributing

This is a basic script and it works as it is... but if you want to improve it or make it cleaner, feel free.

## Todo

- Support for multiple IP addresses with different schedules
- Automatic updates to the list of Blacklists (probably using invoke-webrequest and a public gist)
- Encrypted password for sending out SMTP
