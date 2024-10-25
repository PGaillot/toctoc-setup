#!/bin/bash
# Script de configuration du point d'accès Raspberry Pi
# Basé sur le tutoriel de raspberrypi-guide.com
# https://raspberrypi-guide.github.io/networking/create-wireless-access-point

LOG_FILE="/home/toctoc/config_log.txt"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Début de la configuration : $(date)"

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
        echo "- ☑️ : $1"
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

cat <<EOF >/etc/systemd/system/reset_trigger.service
[Unit]
Description=Service pour gérer la détection du bouton reset.
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 /home/toctoc/toctoc-setup/reset_trigger.py
WorkingDirectory=/home/toctoc/toctoc-setup/
StandardOutput=inherit
StandardError=inherit
Restart=always
User=toctoc

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start reset_trigger.service
systemctl enable reset_trigger.service
check_command "Configuration du service trigger_reset"
echo "Démarrage du service de détection du bouton..."

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
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
check_command "Configuration du pare-feu"

# Sauvegarde des règles iptables
netfilter-persistent save
check_command "Sauvegarde des règles iptables"

# --- Installation de Lighttpd ---
apt install lighttpd -y
check_command "Installation de Lighttpd"

echo "-- 🎉 Configuration (presque) terminee ! 🎉 --"
echo "Vous allez perdre la connection wifi. Pas de panique, c'est normal !"
echo "Veuillez patienter le temps que le Raspberry Pi termine (environ 2 minutes)."
echo "---"
echo "Configuration du point d'accès : TocToc-$ID"
echo " - SSID: TocToc-$ID"
echo " - Mot de passe: $PASSWORD"
echo "Adresse IP statique: 192.168.4.1/24"

# Déconnexion du réseau WiFi actuel
nmcli device disconnect wlan0

# Démarrage des services
systemctl unmask hostapd
systemctl enable hostapd

sleep 3  # Pause de 3 secondes pour laisser dhcpcd se configurer correctement
systemctl start dnsmasq
systemctl start hostapd
check_command "Démarrage des services WiFi"

git clone https://github.com/PGaillot/toctoc-conect-frontend.git
mkdir -p /var/www/html/
cp -rf toctoc-conect-frontend/dist/toctoc-conect-frontend/browser/* /var/www/html/
check_command "Copie du front-end"

chown -R www-data:www-data /var/www/html
check_command "Attribution des droits au dossier /var/www/html"

chmod -R 750 /var/www/html
check_command "Mise à jour des permissions pour /var/www/html"

# Configuration de Lighttpd pour utiliser l'adresse IP statique
cat <<EOF >/etc/lighttpd/lighttpd.conf
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_compress",
    "mod_redirect",
    "mod_mimetype"
)

server.document-root = "/var/www/html"
index-file.names = ( "index.html" )
server.port = 80
server.bind = "192.168.4.1"
server.errorlog = "/var/log/lighttpd/error.log"
server.pid-file = "/var/run/lighttpd.pid"
server.username = "www-data"
server.groupname = "www-data"

mimetype.assign = (
    ".html" => "text/html",
    ".css" => "text/css",
    ".js" => "application/javascript",
    ".jpg" => "image/jpeg",
    ".png" => "image/png"
)
EOF
check_command "Configuration de Lighttpd"

lighttpd -t -f /etc/lighttpd/lighttpd.conf >> $LOG_FILE

# Redémarrage et activation de Lighttpd
systemctl restart lighttpd >> $LOG_FILE
systemctl enable lighttpd >> $LOG_FILE
check_command "Démarrage de Lighttpd"


python3 "$led_control" success

echo "Lighttpd est installé et configuré."
echo "Vous pouvez vous connecter au Raspberry Pi via Wi-Fi et accéder au site web via l'adresse http://192.168.4.1"