#!/bin/bash

IPFILE=<IPv4 FILE> #The file where you store your "old" IPv4 address, for example /home/username/ip
OLDIP=`cat $IPFILE`
NEWIP=`curl ifconfig.me`
#NEWIP=`curl ifconfig.me/ip` #Optional page to get IPv4 address, if the first one does not working. Also you can use your own method/page to get your actual IPv4 address.

#echo "[$OLDIP] - [$NEWIP]" #Debug

if [[ "$OLDIP" != "$NEWIP" ]] ;then

    CLOUDFLARE_API_TOKEN=<CLOUDFLARE API TOKEN> #Your CloudFlare API TOKEN
    #Token verification
    validToken=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type:application/json" | jq .success)
    if [[ "$validToken" == "true" ]] ;then
        #Token is valid
        unset validToken
        #Searching the specific zone
        ZONE_ID=$(curl -X GET "https://api.cloudflare.com/client/v4/zones?name=<ZONE NAME>" \
            -H "Content-Type:application/json" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq -r .result[0].id)
        if [[ "$ZONE_ID" != "null" ]] ;then
            #Zone found
            TOTAL_COUNT=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&content=$OLDIP" \
                -H "Content-Type:application/json" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"|jq -r .result_info.total_count)
            #$TOTAL_COUNT - The number of records with an invalid ipv4 address that will be changed
            COUNTER=0
            while [[ "$COUNTER" -lt "$TOTAL_COUNT" ]]
            do
                RECORD_ID=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&content=$OLDIP" \
                    -H "Content-Type:application/json" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"|jq -r '{"result"}[] | .[0] | .id')

                RECORD_NAME=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&content=$OLDIP" \
                    -H "Content-Type:application/json" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"|jq -r '{"result"}[] | .[0] | .name')

                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
                -H "Content-Type:application/json" \
                -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
                --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$NEWIP\",\"ttl\":1,\"proxied\":false}"

                let COUNTER++
            done
            #Overwrite old IPv4 file with new one
            echo "$NEWIP" > $IPFILE
            #Optionally you can send email with your email client (for me it is mutt)
            #echo -e "$(date) - Your IPv4 address has been changed from $OLDIP to $NEWIP" | mutt -s "Your IPv4 address has been changed on CloudFlare - zone name" <your e-mail address>
        else
            #Zone not found
        fi
    else
        #Token is invalid
    fi
else
    #The new IPv4 address is the same as the old one
fi
