#!/bin/bash
# Script de configuration du point d'accès Raspberry Pi et lancement d'un serveur web avec Flask

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
apt install dnsmasq -y
install_if_needed "hostapd"
install_if_needed "iptables"
install_if_needed "iptables-persistent"
install_if_needed "dhcpcd5"
install_if_needed "lighttpd"

# Installation de python3-venv pour Flask
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    apt install python3-venv -y
    check_command "Installation de python3-venv"
fi

# Création de l'environnement virtuel Flask
if [ ! -d "/home/toctoc/myenv" ]; then
    python3 -m venv /home/toctoc/myenv
    check_command "Création de l'environnement virtuel Flask"
fi

# Activation de l'environnement virtuel
source /home/toctoc/myenv/bin/activate
check_command "Activation de l'environnement virtuel"

# Installation de Flask
pip install flask
check_command "Installation de Flask"
deactivate

# Configuration de l'adresse IP statique
if ! grep -q "static ip_address=192.168.4.1/24" /etc/dhcpcd.conf; then
    cat <<EOF >>/etc/dhcpcd.conf

interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant
EOF
    check_command "Configuration de l'adresse IP statique"
fi

# Redémarrage du service dhcpcd
systemctl restart dhcpcd
check_command "Redémarrage de dhcpcd"

# Configuration de dnsmasq
if ! grep -q "dhcp-range=192.168.4.2,192.168.4.20" /etc/dnsmasq.conf; then
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
if ! grep -q '^DAEMON_CONF="/etc/hostapd/hostapd.conf"' /etc/default/hostapd; then
    sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
    check_command "Configuration du daemon hostapd"
fi

# Activation du routage IP
if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then
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

# Configuration du serveur web Flask
FLASK_APP_DIR="/home/toctoc/toctoc-setup/flask_app"
mkdir -p $FLASK_APP_DIR

cat <<EOF >$FLASK_APP_DIR/app.py
from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0')
EOF

mkdir -p $FLASK_APP_DIR/templates
cat <<EOF >$FLASK_APP_DIR/templates/index.html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue sur TocToc</title>
</head>
<body>
    <h1>Bienvenue sur TocToc</h1>
    <p>Le point d'accès Wi-Fi est configuré avec succès !</p>
</body>
</html>
EOF

# Démarrage de l'application Flask
echo "Démarrage du serveur web Flask..."
source /home/toctoc/myenv/bin/activate
nohup python3 $FLASK_APP_DIR/app.py > flask.log 2>&1 &
deactivate
check_command "Démarrage du serveur Flask"

# Déconnexion du réseau WiFi actuel (si connecté)
nmcli device disconnect wlan0

# Démarrage des services
systemctl unmask hostapd
systemctl enable hostapd
systemctl start dnsmasq
systemctl start hostapd
systemctl start lighttpd

echo "-----------------------------------------------------------------------------------------"
echo "----| 🎉 Configuration terminée !"
echo "----| Le Raspberry Pi est configuré en point d'accès Wi-Fi."
echo "----| SSID: TocToc-$ID"
echo "----| Mot de passe: $PASSWORD"
echo "----| Adresse IP statique: 192.168.4.1/24"
echo "----| Vous pouvez accéder à la page web à l'adresse http://192.168.4.1/"
echo "-----------------------------------------------------------------------------------------"