#!/bin/bash

GATEWAY_HOSTNAME=ssg
GATEWAY_PORT=8443

GATEWAY_SERVICE_URL=(test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test2 test3 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4)
ORG_ID=(HR FINANCE FACILITIES QUALITY PRODUCTION SALES)

echo "Sending requests to host '${GATEWAY_HOSTNAME}' on port '${GATEWAY_PORT}'....."
echo "Press Ctrl + C to cancel"

# Loop forever
# Send request to random endpoints.
a=0
while [ $a -lt 1000 ]; do
	rand_index=$((RANDOM % ${#GATEWAY_SERVICE_URL[@]}))
	#echo "${rand_index}"
	org_index=$((RANDOM % ${#ORG_ID[@]}))
	curl --silent --show-error https://$GATEWAY_HOSTNAME:${GATEWAY_PORT}/${GATEWAY_SERVICE_URL[$rand_index]}?orgid=$org_index --insecure >/dev/null

	rand_sleep=$((RANDOM % 1000))
	rand_sleep_sec=$(echo "scale=3; $rand_sleep / 10000" | bc)
	echo $a
	a=$(expr $a + 1)
	echo "sleep ${rand_sleep_sec} seconds"
	sleep ${rand_sleep_sec}
done

exit 0
