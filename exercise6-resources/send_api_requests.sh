#!/bin/bash

GATEWAY_HOSTNAME=ssg
GATEWAY_PORT=8443

GATEWAY_SERVICE_URL=(test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test1 test2 test3 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4 test4)
ORG_ID=(HR FINANCE QA QA QA QA PROD PROD SALES)

echo "Sending requests to host '${GATEWAY_HOSTNAME}' on port '${GATEWAY_PORT}'....."
echo "Press Ctrl + C to cancel"

# Loop forever
# Send request to random endpoints.
a=0
while [ $a -lt 1000 ]; do
	rand_index=$((RANDOM % ${#GATEWAY_SERVICE_URL[@]}))
	org_index=$((RANDOM % ${#ORG_ID[@]}))
	curl --silent --show-error https://$GATEWAY_HOSTNAME:${GATEWAY_PORT}/${GATEWAY_SERVICE_URL[$rand_index]}?orgid=${ORG_ID[$org_index]}  --insecure >/dev/null
	echo $a
	a=$(expr $a + 1)
done

exit 0
