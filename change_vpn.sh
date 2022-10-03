#!/usr/bin/env bash
# if the VPN is not connected, connect it from the list of available VPNs from the config file
LIST_OF_VPN=$(ls /etc/openvpn/client/ |grep conf | sed 's/.conf//g')
COUNT_OF_VPN=0
for VPN in $LIST_OF_VPN
do
    COUNT_OF_VPN=$((COUNT_OF_VPN+1))
done

#get connection_status
CONNECTION_STATUS=$(systemctl status openvpn-client@* | grep Active | awk '{print $2}')

# if connection is active ,get the name of the VPN from the g
if [ "$CONNECTION_STATUS" == "active" ]; then
    VPN_NAME=$(systemctl status openvpn-client@* | grep Group ) #/system.slice/system-openvpn\x2dclient.slice/openvpn-client@VPN_NAME.service
    VPN_NAME=${VPN_NAME##*openvpn-client@} #VPN_NAME.service
    VPN_NAME=$(echo $VPN_NAME | sed 's/.service//g')
fi

#random number between 1 and the number of available VPNs
RANDOM_NUMBER=$(($RANDOM % $COUNT_OF_VPN ))
# if connection is active ,randomly select a VPN!=VPN_NAME from the list of available VPNs
CHOOSE_STATUS=0
while [ $CHOOSE_STATUS == 0 ] && [ "$CONNECTION_STATUS" == "active" ]
do
    RANDOM_NUMBER=$(($RANDOM % $COUNT_OF_VPN ))
    COUNT=0
    if [ "$CONNECTION_STATUS" == "active" ]; then
        for VPN in $LIST_OF_VPN;
        do
            if [ "$COUNT" -ne "$RANDOM_NUMBER" ]; then
                COUNT=$((COUNT+1))

            else
                if [ "$VPN" != "$VPN_NAME" ]; then
                    VPN_TO_CONNECT=$VPN
                    CHOOSE_STATUS=1
                    break
                else
                    CHOOSE_STATUS=0
                fi
            fi
        done
    fi

done


# if connection is not active ,randomly select a VPN from the list of available VPNs
if [ "$CONNECTION_STATUS" != "active" ]; then
    COUNT=0
    for VPN in $LIST_OF_VPN; do
        if [ "$COUNT" -ne "$RANDOM_NUMBER" ] ;then
            COUNT=$((COUNT+1))

        else
            VPN_TO_CONNECT=$VPN
            CHOOSE_STATUS=1
            break
        fi
    done
fi

# if CONNECTION_STATUS is active ,disconnect the VPN
if [ "$CONNECTION_STATUS" == "active" ]; then
    systemctl stop openvpn-client@*.service
fi

# connect the VPN
systemctl start openvpn-client@$VPN_TO_CONNECT




#slepp 3 seconds
python3 -c "import time; time.sleep(3)"

# get the ipv4 address of the VPN
echo "VPN connected to $VPN_TO_CONNECT"
IPV4=$(wget -qO- http://ipecho.net/plain)
echo   "IPV4 address of the VPN :" $IPV4

# iptables -t nat -I POSTROUTING 1 -s 10.8.0.0/24 -o tun1 -j MASQUERADE
