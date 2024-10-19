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

# Fonction pour installer un paquet s'il n'est pas déjà présent
install_if_needed() {
    if ! dpkg -l | grep -q $1; then
        apt install $1 -y
        check_command "Installation de $1"
    else
        echo "- ☑️ : $1 est déjà installé."
    fi
}

# Installation des paquets nécessaires
# install_if_needed "dnsmasq"
apt install dnsmasq -y
install_if_needed "hostapd"
install_if_needed "iptables"
install_if_needed "iptables-persistent"
install_if_needed "dhcpcd5"
install_if_needed "lighttpd"

# copie de l'application https://github.com/PGaillot/toctoc-conect-frontend
if [ ! -d "/home/toctoc/toctoc-setup/toctoc-conect-frontend" ]; then
    git clone https://github.com/PGaillot/toctoc-conect-frontend.git
    check_command "Copie de l'application frontend"
else
    echo "- ☑️ : Le dépôt existe déjà, mise à jour du dépôt"
    cd /home/toctoc/toctoc-setup/toctoc-conect-frontend
    git pull
    cd ../
fi
check_command "Copie de l'application frontend"

# Installation de python3-venv
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    sudo apt install python3-venv -y
    check_command "Installation de python3-venv"
else
    echo "- ☑️ : python3-venv est déjà installé."
fi

# Création de l'environnement virtuel
if [ ! -d "myenv" ]; then
    python3 -m venv myenv
    check_command "Création de l'environnement virtuel"
else
    echo "- ☑️ : L'environnement virtuel 'myenv' existe déjà."
fi

# Activation de l'environnement virtuel
if [ -d "myenv" ]; then
    source myenv/bin/activate
    check_command "Activation de l'environnement virtuel"
else
    echo "❌ Erreur: Impossible d'activer l'environnement virtuel car 'myenv' n'existe pas."
    exit 1
fi

# Installation de flask
pip install flask
deactivate
check_command "Installation de flask & desactivation de l'environnement virtuel"

# Arrêt des services
systemctl stop dnsmasq
systemctl stop hostapd

# Configuration de l'adresse IP statique
if grep -q "static ip_address=192.168.4.1/24" /etc/dhcpcd.conf; then
    echo "- ✔️ : L'adresse IP statique est déjà configurée."
else
    cat <<EOF >/etc/dhcpcd.conf

interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF
    check_command "Configuration de l'adresse IP statique"
fi

# Redémarrage du service dhcpcd
systemctl restart dhcpcd
check_command "Redémarrage de dhcpcd"

# Sauvegarde et configuration de dnsmasq
if [ ! -f "/etc/dnsmasq.conf.orig" ]; then
    mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
    check_command "Sauvegarde du fichier de configuration original de dnsmasq"
else
    echo "- ✔️ : Le fichier de configuration original de dnsmasq a déjà été sauvegardé."
fi

# Vérification avant d'écrire la configuration
if grep -q "dhcp-range=192.168.4.2,192.168.4.20" /etc/dnsmasq.conf; then
    echo "- ✔️ : La configuration de dnsmasq est déjà présente."
else
    cat <<EOF >/etc/dnsmasq.conf
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF
    check_command "Configuration de dnsmasq"
fi

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

# Vérification de la configuration du daemon hostapd
if grep -q '^DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd; then
    echo "- ✔️ : La configuration du daemon hostapd est déjà présente."
else
    sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
    check_command "Configuration du daemon hostapd"
fi

# Activation du routage IP
if grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then
    echo "- ✔️ : Le routage IP est déjà activé."
else
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
    sysctl -p
    check_command "Activation du routage"
fi

# Configuration du pare-feu
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
check_command "Configuration du pare-feu"

# Sauvegarde des règles iptables
netfilter-persistent save
check_command "Sauvegarde des règles iptables"

sudo rm /var/www/html/index.lighttpd.html
sudo cp -r /home/toctoc/toctoc-setup/toctoc-conect-frontend/dist/toctoc-conect-frontend/browser/* /var/www/html/
echo "Configuration de l'application frontend"

echo "-----------------------------------------------------------------------------------------"
echo "----|   🎉 Configuration (presque) terminee !"
echo "----|   Vous allez perdre la connection wifi. C'est normal !"
echo "----|   Veuillez patienter le temps que le  le Raspberry Pi termine et redemarre (environ 5 minutes)."
echo "----|   Configuration du point d'accès : TocToc-$ID"
echo "----|   - SSID: TocToc-$ID"
echo "----|   - Mot de passe: $PASSWORD"
echo "----|   Adresse IP statique: 192.168.4.1/24"
echo "-----------------------------------------------------------------------------------------"

chmod +x /home/toctoc/toctoc-setup/control_led.py
echo "Allumage de la LED pour indiquer que le Wi-Fi est prêt. (TEST)"
python3 /home/toctoc/toctoc-setup/control_led.py

# Déconnexion du réseau WiFi actuel (si connecté)
nmcli device disconnect wlan0

# Démarrage des services
systemctl unmask hostapd
systemctl enable hostapd
systemctl start dnsmasq
systemctl start hostapd
systemctl start lighttpd

source myenv/bin/activate
nohup python3 scan_wifi.py > log_scan_wifi.txt 2>&1 &


