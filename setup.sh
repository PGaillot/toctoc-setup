#!/bin/bash
# Script de configuration du point d'accès Raspberry Pi
# Basé sur le tutoriel de raspberrypi-guide.com
# https://raspberrypi-guide.github.io/networking/create-wireless-access-point

total_steps=$(grep -c "check_command" "$0")
current_step=0
# Fonction pour vérifier si une commande s'est bien exécutée
led_control="/home/toctoc/toctoc-setup/led_control.py"
sudo apt-get install python3-rpi.gpio
python3 "$led_control" warning

check_command() {
    if [ $? -ne 0 ]; then
        echo "❌ Erreur: $1"
        python3 "$led_control" error
        exit 1
    else
        current_step=$((current_step + 1))  # Incrémente current_step correctement
        echo "[$current_step/$total_steps] - ☑️ : $1"
    fi
}

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

python3 "$led_control" warning
cp ./config/reset_trigger.service /etc/systemd/system/reset_trigger.service

systemctl daemon-reload
systemctl start reset_trigger.service
systemctl enable reset_trigger.service
check_command "Configuration du service trigger_reset"

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
cp ./config/dhcpcd.conf /etc/dhcpcd.conf
check_command "Configuration de l'adresse IP statique"

# Redémarrage du service dhcpcd
systemctl restart dhcpcd
check_command "Redémarrage de dhcpcd"

# Configuration de dnsmasq
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
cp ./config/dnsmasq.conf /etc/dnsmasq.conf
check_command "Configuration de dnsmasq"

# Configuration de hostapd
sed -i "/wpa_passphrase=/c\\wpa_passphrase=$PASSWORD" ./config/hostapd.conf
sed -i "/^ssid=TocToc-/c\ssid=TocToc-$ID" ./config/hostapd.conf
cp ./config/hostapd.conf /etc/hostapd/hostapd.conf
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
nmcli device disconnect wlan0

# Démarrage des services
systemctl unmask hostapd
systemctl enable hostapd
systemctl start dnsmasq
systemctl start hostapd
python3 "$led_control" success