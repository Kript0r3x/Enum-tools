#!/bin/bash

# Function to display help message
function show_help {
    echo "Usage: $0 [USERNAME] [PASSWORD] [DOMAIN]"
    echo "  USERNAME - The username for authentication (default: guest)"
    echo "  PASSWORD - The password for authentication"
    echo "  DOMAIN   - The target domain for queries"
    echo "If PASSWORD is not provided, the script will prompt for it."
}

# Check for --help argument
if [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

# Set default values and read command line arguments
USER=${1:-guest}
PASSWORD=${2}
DOMAIN=${3:-'jab.htb'}

# Check if PASSWORD is provided, if not, prompt for it
if [ -z "$PASSWORD" ]; then
    echo "Please enter password:"
    read -s PASSWORD
fi

# find domain info
echo "[+] dumping domain info"
rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c 'querydominfo; quit;' > domain_info.txt

# find all users & save the result in txt file
echo "[+] Dumping users"
rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c 'enumdomusers; quit;' | awk '{print $1}' | awk -F: '{print $2}' | cut -f 2 -d '[' | cut -f 1 -d ']' > users.txt

# find users RID & save the results in txt file
echo "[+] Duming users rid"
rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c 'enumdomusers; quit;' | awk '{print $2}' | awk -F: '{print $2}' | cut -f 2 -d '[' | cut -f 1 -d ']' > users_rid.txt

# find groups & save the results in txt file
echo "[+] Dumping groups"
rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c 'enumdomgroups; quit;' | awk -F[ '{print $2}' | awk -F] '{print $1}' > groups.txt

# find groups RID & save the results in txt file
echo "[+] Dumping groups rid"
rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c 'enumdomgroups; quit;' | awk -F] '{print $2}' | awk -F: '{print $2}' | cut -f 2 -d '[' > groups_rid.txt

# find domain password policy
echo "[+] Dumping domain password policy"
rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c 'getdompwinfo; quit;' > domain_password_policy.txt

# dumping all users details (this may take a lot of time depends on user count available on domain)
# this type of recon is important because we can find some private infos posted in public places like Description field.
echo "[+] Start dumping detailed user info's"
for rid in $(cat users_rid.txt); do
    rpcclient -U "$DOMAIN/$USER%$PASSWORD" -I 10.10.11.4 dc01.jab.htb -c "queryuser $rid; quit;"
done
