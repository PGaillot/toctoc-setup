import RPi.GPIO as GPIO
import sys
import time

# Définir les ports des LED
LED_VERTE = 21  # Succès
LED_ORANGE = 20  # Warning
LED_ROUGE = 26  # Erreur

# Initialiser les ports GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED_VERTE, GPIO.OUT)
GPIO.setup(LED_ORANGE, GPIO.OUT)
GPIO.setup(LED_ROUGE, GPIO.OUT)

# Fonction pour allumer une LED et éteindre les autres
def allumer_led(led):
    GPIO.output(LED_VERTE, GPIO.LOW)
    GPIO.output(LED_ORANGE, GPIO.LOW)
    GPIO.output(LED_ROUGE, GPIO.LOW)
    GPIO.output(led, GPIO.HIGH)

# Fonction pour gérer l'état des LED et retourner un code de sortie
def led_status(status):
    if status == "success":
        allumer_led(LED_VERTE)
        return 0  # Succès
    elif status == "warning":
        allumer_led(LED_ORANGE)
        return 1  # Warning
    elif status == "error":
        allumer_led(LED_ROUGE)
        return 2  # Erreur
    else:
        print("Statut inconnu")
        return 3  # Statut inconnu

# Lecture du statut passé en argument
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage : python3 led_manager.py [success|warning|error]")
        sys.exit(3)

    status = sys.argv[1]
    exit_code = led_status(status)
    
    sys.exit(exit_code)
