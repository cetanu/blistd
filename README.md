# blistd <sup>DNS Blacklist Lookup</sup>

---

## About

This is a Powershell script which checks each DNS Blacklist to see if your IP has been listed.  

## Features

- Randomized wait between executions so that we don't look like robots to the DNSBL hosts
- Email alerting via SMTP (password is stored securely)
- Automatically downloads a list of DNSBLs from [here](https://gist.github.com/cetanu/9697771)
- Logging

## How to use this thing

1. Simply download the script
3. Change the IP and Email settings to whatever is appropriate for your environment
3. Run the script.
7. Done

## Contributing

This is a basic script and it works as it is... but if you want to improve it or make it cleaner, feel free.

## Todo

- **DONE:** Support for multiple IP addresses
- **DONE:** Automatic updates to the list of Blacklists
- **DONE:** Encrypted password for sending out SMTP ( Needs testing )
- **DONE:** Added python version for *nix platforms
- Different schedules per IP? Is this even necessary?
