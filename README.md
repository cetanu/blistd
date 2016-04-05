# :fire: banishd :fire:

#### DNS Blacklist Lookup

A cut-down version of blistd (below)

Does everything the same, but doesn't download a gist every time you run it.

# blistd

#### DNS Blacklist Lookup

## About

This is a script written in Python which checks each DNS Blacklist to see if your IP has been listed.  


## Features

- Automatically downloads a list of DNSBLs from [here][1]
- Email alerting via SMTP
- Logging
- Randomized wait between executions so that we don't look too much like robots to the DNSBL hosts


## Instructions

1. Download.
3. Change the IP and Email settings.
3. Execute.
7. Done.


[1]: https://gist.github.com/cetanu/9697771
