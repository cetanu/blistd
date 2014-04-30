# blistd <sup>DNS Blacklist Lookup</sup>

---

## About

This is a script written in two version, Powershell and Python, which checks each DNS Blacklist to see if your IP has been listed.  

## Features

- Automatically downloads a list of DNSBLs from [here](https://gist.github.com/cetanu/9697771)
- Email alerting via SMTP
- Logging
- Randomized wait between executions so that we don't look too much like robots to the DNSBL hosts


## Instructions

1. Download.
3. Change the IP and Email settings.
3. Execute.
7. Done.

## Contributing

Please raise an issue if you would like to make a change.  
Don't fork if it can be resolved in my code!

## Todo

- **DONE:** Support for multiple IP addresses
- **DONE:** Automatic updates to the list of Blacklists
- **DONE:** Encrypted password for sending out SMTP ( Needs testing )
- **DONE:** Added python version for *nix platforms
- Close the gap between Powershell and Python version:
  - Add secure credential storage for smtp
  - Ask if the user wants to continue, taking into account the last time the gist was updated
  - Maybe strip out some unnecessary things from the Powershell version
- Remove some of the `exit`s and make the script keep running even when it can't do things like email or contact the network, for more consistent logging.