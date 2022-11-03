## General info
This is a [simple bash script](cloudflare-ip-check.sh) that checks if your public IPv4 address has changed, if so, it changes it in your specific CloudFlare zone using their API.

## Requirements
* CloudFlare API Token for your specific zone
* jq -  to interpret and work with JSON
* curl
* public IPv4
* task scheduler - e.g. cron

## Configuration
To run this script, you need to:

1. Specify the file where you will store your "old" IPv4 address, for example /home/youruser/ip:
```
    IPFILE=<IPv4 FILE>
```
2. Put the generated CloudFlare API token for your ZONE:
```
    CLOUDFLARE_API_TOKEN=<CLOUDFLARE API TOKEN>
```
3. Specify the name of your zone:
```
    ZONE_ID=$(curl -X GET "https://api.cloudflare.com/client/v4/zones?name=<ZONE NAME>" \
```
4. Optionally, on last step you can send email with your email client (for me it is mutt), when the IPv4 has been changed:
```
echo -e "$(date) - Your IPv4 address has been changed from $OLDIP to $NEWIP" | mutt -s "Your IPv4 address has been changed on CloudFlare - zone name" <your e-mail address>
```
5. Add automatic script execution to the schedule of tasks at a specified time, for example crontab:
```
*/15 *  * * *   <user>      /<path-to-scripts>/cloudflare-ip-check.sh
```

Also I left else statements, so you can make your own e.g. error alert, logs.
