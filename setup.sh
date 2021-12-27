#!/bin/sh
#./setup.sh -h hostname
USAGE="usage:$0 -i <dhcp_interface:wlan0/eth0> -s <accesspoint-ssid> -p <accesspoint-pw>"
HOSTAP_SSID="pi-fx-led"
HOSTAP_PW="pifx1234"
#DHCP_IFACE="wlan0"
DHCP_IFACE="eth0"

while getopts p:s:i: f
do
        case $f in
        s) HOSTAP_SSID=$OPTARG ;;
        p) HOSTAP_PW=$OPTARG ;;
        i) DHCP_IFACE=$OPTARG ;;
        esac
done

if [ $(id -u) -ne 0 ]; then
        echo "Please run setup as root ==> sudo -i ./setup.sh <dhcp_interface:wlan0/eth0> -s <accesspoint-ssid> -p <accesspoint-pw>"
        exit
fi

echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> /etc/default/hostapd

printf "Installing dependencies ................................ "
DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing < /dev/null > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -qq hostapd dnsmasq pavucontrol gcc libatlas3-base libavformat58 portaudio19-dev pulseaudio python3-pip avahi-daemon < /dev/null > /dev/null
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

printf "Installing led-fx ...................................... "
./led-fx-install.sh 1>/dev/null 2>/dev/null
#echo "LedFx is now running. Please navigate to "$IP":8888 in your web browser"
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

printf "Configuring dhcp server ................................ "
echo "interface=$DHCP_IFACE" >> /etc/dnsmasq.conf
echo "  dhcp-range=192.168.0.2,192.168.0.30,255.255.255.0,24h" >> /etc/dnsmasq.conf
test 0 -eq $? && echo "[OK]" || echo "[FAIL]"

if [ $DHCP_IFACE = "wlan0" ]; then
    printf "Configuring hostapd .................................... "
    touch /etc/hostapd/hostapd.conf
    echo "interface=$DHCP_IFACE" > /etc/hostapd/hostapd.conf
    echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
    echo "channel=7" >> /etc/hostapd/hostapd.conf
    echo "wmm_enabled=0" >> /etc/hostapd/hostapd.conf
    echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
    echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
    echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
    echo "wpa=2" >> /etc/hostapd/hostapd.conf
    echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
    echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
    echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
    echo "ssid=$HOSTAP_SSID" >> /etc/hostapd/hostapd.conf
    echo "wpa_passphrase=$HOSTAP_PW" >> /etc/hostapd/hostapd.conf
    test 0 -eq $? && echo "[OK]" || echo "[FAIL]"
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo raspi-config nonint do_wifi_country DE
fi