# TocToc-setup

## Préparation de la carte SD

### Prérequis
Télécharger la dernière version de [Raspberry Pi Imager](https://www.raspberrypi.com/software/) pour votre ordinateur [windows](https://downloads.raspberrypi.org/imager/imager_latest.exe), [Mac](https://downloads.raspberrypi.org/imager/imager_latest.dmg) ou [Ubuntu x86](https://downloads.raspberrypi.org/imager/imager_latest_amd64.deb).

- **image** : Raspberry Pi OS Lite(32bit).
- **model** : Raspberry Pi Zero W.
- **stockage** : une carte micro-sd de 16go minimum.
  
---

dans la fenêtre d'option choisir de modifier les réglages avec : 
#### Général
- [x] nom d'hôte : *raspizerow*.local
- [x] Définir nom d'utilisateur en mot de passe
  - Nom d'utilisateur : *toctoc*
  - Mot de passe : *Votre-mot-de-passe*
- [x] Configurer le Wi-Fi

#### Services
- [x] Activer SSH
  - [x] utiliser un mot de passe pour l'authentification.

## Trouver l'ip du raspberry
https://raspberry-pi.fr/trouver-adresse-ip-raspberry-pi/

## Se connecter en SSH
- 1 - `ssh toctoc@raspizerow.local` ou `ssh toctoc@192.168.1.XX` (*votre ip*)
- 2 - Entrez votre *mot de passe*
- 3 - `sudo apt update`
- 4 - `sudo apt upgrade`
- 5 - `sudo apt install git -y && sudo apt install vim -y`
- 6 - `cd /home/toctoc/`
- 7 - `git clone https://github.com/PGaillot/TocToc-setup.git`
- 8 - `cd toctoc-setup/`
- 9 - `sudo chmod +x setup.sh`
- 10 - `sudo ./setup.sh -s MonWiFi -i ID-DU-DEVICE -w WIFI-PASSWORD`  

--- 

### Connection
Par defaut le SSID du wifi est *TocToc-123* et le password *Toc*2=T0Ct0C!*
