import RPi.GPIO as GPIO
import sys
import time
import threading

# Définir les ports des LED
LED_VERTE = 21  # Succès
LED_ORANGE = 20  # Warning
LED_ROUGE = 26  # Erreur

# Initialiser les ports GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)
GPIO.setup(LED_VERTE, GPIO.OUT)
GPIO.setup(LED_ORANGE, GPIO.OUT)
GPIO.setup(LED_ROUGE, GPIO.OUT)

# Variable pour contrôler le clignotement
clignotement_actif = False
thread_clignotement = None

def clignoter_led(led, vitesse=0.5):
    global clignotement_actif
    clignotement_actif = True

    while clignotement_actif:
        GPIO.output(led, GPIO.HIGH)
        time.sleep(vitesse)
        GPIO.output(led, GPIO.LOW)
        time.sleep(vitesse)

# Fonction pour démarrer le clignotement dans un thread
def demarrer_clignotement(led, vitesse=0.5):
    global thread_clignotement
    if thread_clignotement is None or not thread_clignotement.is_alive():
        thread_clignotement = threading.Thread(target=clignoter_led, args=(led, vitesse))
        thread_clignotement.start()

# Fonction pour arrêter le clignotement
def arreter_clignotement():
    global clignotement_actif
    clignotement_actif = False
    if thread_clignotement:
        thread_clignotement.join()

# Fonction pour allumer une LED et éteindre les autres
def allumer_led(led):
    eteindre_leds()
    GPIO.output(led, GPIO.HIGH)

def eteindre_leds():
    GPIO.output(LED_VERTE, GPIO.LOW)
    GPIO.output(LED_ORANGE, GPIO.LOW)
    GPIO.output(LED_ROUGE, GPIO.LOW)

# Fonction pour gérer l'état des LED
def led_status(status):
    if status == "success":
        arreter_clignotement()
        allumer_led(LED_VERTE)
    elif status == "loading":
        demarrer_clignotement(LED_VERTE)
    elif status == "warning":
        arreter_clignotement()
        allumer_led(LED_ORANGE)
    elif status == "error":
        arreter_clignotement()
        allumer_led(LED_ROUGE)
    else:
        print("Statut inconnu")
        arreter_clignotement()
        allumer_led(LED_ROUGE)

# Lecture du statut passé en argument
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage : python3 led_manager.py [success|loading|warning|error]")
        sys.exit(1)

    status = sys.argv[1]
    led_status(status)

    # Libère les GPIO après exécution
    GPIO.cleanup()