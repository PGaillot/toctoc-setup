from flask import Flask, render_template

app = Flask(__name__)

@app.route('/')
def home():
    return "Bienvenue sur la page d'accueil du Raspberry Pi!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)