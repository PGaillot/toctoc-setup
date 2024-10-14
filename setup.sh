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
sudo apt ugrade -y
sudo apt install dnsmasq hostapd

# Arrêt des services
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

# Configuration de l'adresse IP statique
cat << EOF >> /etc/dhcpcd.conf

interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF

# Redémarrage du service dhcpcd
sudo service dhcpcd restart

# Configuration de dnsmasq
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat << EOF > /etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF

# Démarrage de dnsmasq
sudo systemctl start dnsmasq

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
sudo sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd

# Activation et démarrage de hostapd
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd

# Activation du routage
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configuration du pare-feu
sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE

# Sauvegarde des règles iptables
sudo netfilter-persistent save

echo "Configuration terminée. Redémarrez votre Raspberry Pi pour appliquer les changements."