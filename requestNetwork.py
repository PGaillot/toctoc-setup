import subprocess
import re
from flask import Flask, jsonify

app = Flask(__name__)

def request_network(ssid, password):
    # Exécuter la commande de connexion au point d'accès
    result = subprocess.run(['sudo', 'nmcli', 'device', 'wifi', 'connect', ssid, 'password', password], stdout=subprocess.PIPE)
    return result

@app.route('/request', methods=['POST'])
def request():
    ssid = request.args.get('ssid')
    password = request.args.get('password')
    return request_network(ssid, password)