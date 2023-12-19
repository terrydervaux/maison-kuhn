#!/bin/bash

# load dotenv variables
source .env

STATUS=$(curl -w '%{http_code}' \
     -o /dev/null \
     -s \
     "http://$LAN_IP_ADDRESS:$EMULATED_HUE_LISTEN_PORT/description.xml")

if [ $STATUS != 200 ]; then
    echo "Test NOK"
    exit 1;
fi

echo "Test OK"
exit 0;
    
