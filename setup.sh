#!/bin/bash
# Script de configuration du point d'accès Raspberry Pi
# Basé sur le tutoriel de raspberrypi-guide.com
# https://raspberrypi-guide.github.io/networking/create-wireless-access-point

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Valeurs par défaut
ID="123"
PASSWORD="Toc*2=T0Ct0C!"

# Traitement des arguments
while getopts "i:p" opt; do
    case ${opt} in
    i)
        ID=$OPTARG
        ;;
    p)
        PASSWORD=$OPTARG
        ;;
    esac
done

# Fonction pour vérifier si une commande s'est bien exécutée
check_command() {
    if [ $? -ne 0 ]; then
        echo "❌ Erreur: $1"
        exit 1
    else
        echo "- ☑️ : $1"
    fi
}

# Installation des paquets nécessaires
# apt upgrade -y

check_command "intallation de python"
apt install python3-gpiozero
echo "Démarrage du service de détection du bouton..."
/usr/bin/python3 /home/toctoc/toctoc-setup/reset_trigger.py &
echo "Le script de détection du bouton est lancé en arrière-plan."


check_command "Mise à jour des paquets"
apt install dnsmasq -y
check_command "Installation de dnsmasq"
apt install hostapd -y
check_command "Installation de hostapd"
apt install iptables -y
check_command "Installation de iptables"
apt install iptables-persistent -y
check_command "Installation de iptables-persistent"
apt install dhcpcd5 -y
check_command "Installation de dhcpcd5"

# Arrêt des services
systemctl stop dnsmasq
systemctl stop hostapd

# Configuration de l'adresse IP statique
cat <<EOF >/etc/dhcpcd.conf
interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF
check_command "Configuration de l'adresse IP statique"

# Redémarrage du service dhcpcd
systemctl restart dhcpcd
check_command "Redémarrage de dhcpcd"

# Configuration de dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cat <<EOF >/etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF
check_command "Configuration de dnsmasq"

# Configuration de hostapd
cat <<EOF >/etc/hostapd/hostapd.conf
country_code=FR
interface=wlan0
ssid=TocToc-$ID
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
check_command "Configuration de hostapd"

# Indication de l'emplacement du fichier de configuration
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
check_command "Configuration du daemon hostapd"

# Activation du routage
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p
check_command "Activation du routage"

# Configuration du pare-feu
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
check_command "Configuration du pare-feu"

# Sauvegarde des règles iptables
netfilter-persistent save
check_command "Sauvegarde des règles iptables"

echo "🎉 Configuration (presque) terminee !"
echo "Vous allez perdre la connection wifi. C'est normal !"
echo "Veuillez patienter le temps que le  le Raspberry Pi termine et redemarre (environ 5 minutes)."
echo "Configuration du point d'accès : TocToc-$ID"
echo " - SSID: TocToc-$ID"
echo " - Mot de passe: $PASSWORD"
echo "Adresse IP statique: 192.168.4.1/24"

# Déconnexion du réseau WiFi actuel (si connecté)
# nmcli device disconnect wlan0

# Démarrage des services
systemctl unmask hostapd
systemctl enable hostapd
systemctl start dnsmasq
systemctl start hostapd
