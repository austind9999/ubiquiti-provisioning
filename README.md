# Ubiquiti Provisioning - NanoStation AC
This script provides automatic flashing/provisioning capability for Ubiquiti products.

## Overview
This is a bash script that can be executed directly. Testing was done on Ubuntu 20.04, but it should be compatible with most linux distributions.

This script expects the following conditions to be met:
1. The NanoStation AC should have a factory-default IP address of 192.168.1.20.
2. The host machine that's running the script should have an interface in the 192.168.1.0/24 segment, and that network interface should be connected to the NanoStation AC. This can be a direct connection or through a switch or hub.

## Dependencies
Requires: jq, sshpass, curl.

## Example usage
```bash
$ bash provision.sh
```

## Works with these products
1. NanoStation AC
