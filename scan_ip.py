import subprocess
import re
from flask import Flask, jsonify

app = Flask(__name__)

def scan_wifi():
    # Exécute la commande iwlist pour scanner les réseaux Wi-Fi
    result = subprocess.run(['sudo', 'iwlist', 'wlan0', 'scan'], stdout=subprocess.PIPE)
    networks = []
    
    # Analyse la sortie de la commande
    cells = result.stdout.decode('utf-8').split('Cell ')
    for cell in cells[1:]:
        ssid = re.search(r'ESSID:"(.*?)"', cell).group(1) if re.search(r'ESSID:"(.*?)"', cell) else "Inconnu"
        quality = re.search(r'Quality=(\d+)/(\d+)', cell).group(1) if re.search(r'Quality=(\d+)/(\d+)', cell) else "N/A"
        encryption = re.search(r'Encryption key:(on|off)', cell).group(1) if re.search(r'Encryption key:(on|off)', cell) else "N/A"
        if encryption == 'on':
            if re.search(r'WPA2', cell):
                security = "WPA2"
            elif re.search(r'WPA', cell):
                security = "WPA"
            elif re.search(r'WEP', cell):
                security = "WEP"
            else:
                security = "Inconnu"
        else:
            security = "Open"
        
        networks.append({
            'ssid': ssid,
            'quality': quality,
            'security': security
        })
    
    return networks

@app.route('/wifi', methods=['GET'])
def wifi():
    return jsonify(scan_wifi())

if __name__ == '__main__':
    app.run(host='0.0.0.0')