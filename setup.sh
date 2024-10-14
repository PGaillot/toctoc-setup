#!/bin/bash

# Script de configuration du point d'accès Raspberry Pi
# Basé sur le tutoriel de raspberrypi-guide.com
# https://raspberrypi-guide.github.io/networking/create-wireless-access-point

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté en tant que root" 
   exit 1
fi

# Installation des paquets nécessaires
apt install -y dnsmasq hostapd dhcpcd5 netfilter-persistent iptables-persistent

# Arrêt des services
systemctl stop dnsmasq
systemctl stop hostapd

# Configuration de l'adresse IP statique
cat << EOF >> /etc/dhcpcd.conf

interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF

# Redémarrage du service dhcpcd
service dhcpcd restart

# Configuration de dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat << EOF > /etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

# Démarrage de dnsmasq
systemctl start dnsmasq

# Configuration de hostapd
cat << EOF > /etc/hostapd/hostapd.conf
country_code=FR
interface=wlan0
ssid=TocToc
channel=7
auth_algs=1
wpa=2
wpa_passphrase=Toc*2=T0Ct0C!
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
EOF

# Indication de l'emplacement du fichier de configuration
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

# Activation et démarrage de hostapd
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

# Activation du routage
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configuration du pare-feu
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

# Sauvegarde des règles iptables
netfilter-persistent save

echo "Configuration terminée. Redémarrez votre Raspberry Pi pour appliquer les changements."