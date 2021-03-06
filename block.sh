#!/bin/bash

# This script - is triggered by LFD (BLOCK_REPORT)
# 	      - copies LFD blocks to a cloudflare user-level firewall
# 	      - sets the description in cloudflare to "Blocked by LFD on xxx for xxx seconds"
# 	      - Saves the IP and cloudflare rule ID to a file named 'blocked' in the format ip|id

# Directory of THIS script, used for includes.
dir="/etc/csf/scripts/cloudflare"

# Include file, contains api key and other settings
source "$dir/include.sh"

ip=$(printf "%q" $1)
reason=$(printf "%q" $6)
duration=$(printf "%q" $5)

# Build request, for debugging purposes
url="https://api.cloudflare.com/client/v4/user/firewall/access_rules/rules"
emh="X-Auth-Email: $email"
keh="X-Auth-Key: $key"
coh="Content-Type: application/json"
dat='{"mode":"block","configuration":{"target":"ip","value":"'$ip'"},"notes":"Blocked by LFD on '$date' for '$duration' seconds"}'


# Send request to block the IP to cloudflare and save response in variable
response=$(curl --silent --request POST "$url" \
-H "$emh" \
-H "$keh" \
-H "$coh" \
--data "$dat")

# Extract rule ID and status from response
id=$(echo "$response" | jq -r '.["result"]["id"]')
success=$(echo "$response" | jq -r '.["success"]')

# If the request wasn't successful, save the response to $blocklog for debugging
# Else, save the rule ID to $blocked
if [ "$success" != "true" ]; then
	echo "====================" >> "$blocklog"
	echo "===== REQUEST =====" >> "$blocklog"
	echo "$url" >> "$blocklog"
	echo "$emh" >> "$blocklog"
	echo "$keh" >> "$blocklog"
	echo "$coh" >> "$blocklog"
	echo "$dat" >> "$blocklog"
	echo "===== RESPONSE =====" >> "$blocklog"
	echo "$response" >> "$blocklog"
else
	# Add IP, rule ID and reason to blocked file
	# Format: IP|ID|||Reason
	echo "$ip|$id|||$reason" >> "$blocked" 
fi
