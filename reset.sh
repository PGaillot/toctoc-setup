#!/bin/bash
# Script de désinstallation du point d'accès Raspberry Pi

led_control="/home/toctoc/toctoc-setup/led_control.py"

python3 "$led_control" warning

# Vérification des privilèges root
if [[ $EUID -ne 0 ]]; then
    echo "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Fonction pour vérifier si une commande s'est bien exécutée
check_command() {
    if [ $? -ne 0 ]; then
        echo "❌ Erreur: $1"
        exit 1
    else
        echo "- ☑️ : $1"
    fi
}

# Arrêt des services
echo "Arrêt des services hostapd et dnsmasq..."
systemctl stop hostapd
systemctl stop dnsmasq
check_command "Arrêt des services"

# Suppression des fichiers de configuration personnalisés et restauration des fichiers d'origine
echo "Restauration des fichiers de configuration d'origine..."

# Restauration du fichier /etc/dhcpcd.conf
if [ -f /etc/dhcpcd.conf.bak ]; then
    mv /etc/dhcpcd.conf.bak /etc/dhcpcd.conf
    check_command "Restauration de /etc/dhcpcd.conf"
else
    echo "❌ Fichier de sauvegarde /etc/dhcpcd.conf.bak introuvable."
fi

# Restauration du fichier /etc/dnsmasq.conf
if [ -f /etc/dnsmasq.conf.orig ]; then
    mv /etc/dnsmasq.conf.orig /etc/dnsmasq.conf
    check_command "Restauration de /etc/dnsmasq.conf"
else
    echo "❌ Fichier de sauvegarde /etc/dnsmasq.conf.orig introuvable."
fi

# Suppression du fichier de configuration hostapd
if [ -f /etc/hostapd/hostapd.conf ]; then
    rm /etc/hostapd/hostapd.conf
    check_command "Suppression de /etc/hostapd/hostapd.conf"
else
    echo "❌ Fichier /etc/hostapd/hostapd.conf introuvable."
fi

# Désactivation du routage
sed -i 's/net.ipv4.ip_forward=1/#net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p
check_command "Désactivation du routage"

# Suppression des règles iptables ajoutées
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
check_command "Suppression des règles iptables"

# Sauvegarde des règles iptables modifiées
netfilter-persistent save
check_command "Sauvegarde des règles iptables"

# Désactivation et masquage des services
echo "Désactivation des services hostapd et dnsmasq..."
systemctl disable hostapd
systemctl mask hostapd
systemctl disable dnsmasq
check_command "Désactivation des services"

python3 "$led_control" success
echo "🎉 Désinstallation terminée. Le Raspberry Pi est revenu à son état d'origine."
