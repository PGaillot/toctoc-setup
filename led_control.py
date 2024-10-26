import RPi.GPIO as GPIO
import sys
import time

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

def clignoter_led(led, vitesse=0.5):
    eteindre_leds()
    
    try:
        # Clignotement en continu jusqu'à interruption
        while True:
            GPIO.output(led, GPIO.HIGH)
            time.sleep(vitesse)
            eteindre_leds()
            time.sleep(vitesse)
    finally:
        eteindre_leds()
        GPIO.cleanup()  # Libère les GPIO en cas d'interruption

# Fonction pour allumer une LED et éteindre les autres
def allumer_led(led):
    eteindre_leds()
    GPIO.output(led, GPIO.HIGH)
    

def eteindre_leds():
    GPIO.output(LED_VERTE, GPIO.LOW)
    GPIO.output(LED_ORANGE, GPIO.LOW)
    GPIO.output(LED_ROUGE, GPIO.LOW)

# Fonction pour gérer l'état des LED et retourner un code de sortie
def led_status(status):
    if status == "success":
        allumer_led(LED_VERTE)
        return 0  # Succès
    elif status == "loading":
        clignoter_led(LED_VERTE)
        return 2  # Loading
    elif status == "warning":
        allumer_led(LED_ORANGE)
        return 3  # Warning
    elif status == "error":
        allumer_led(LED_ROUGE)
        return 1  # Erreur
    else:
        print("Statut inconnu")
        allumer_led(LED_ROUGE)
        return 1  # Statut inconnu

# Lecture du statut passé en argument
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage : python3 led_manager.py [success|loading|warning|error]")
        sys.exit(1)

    status = sys.argv[1]
    exit_code = led_status(status)
    
    # Libère les GPIO après exécution
    GPIO.cleanup()
    sys.exit(exit_code)