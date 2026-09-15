# Firmware Reverse Engineering — Solution

The Telnet username and password are stored in plain text at the following paths inside the extracted firmware file system:

- Username: `cat etc/scripts/misc/telnetd.sh`
- Password: `cat etc/config/image_sign`
