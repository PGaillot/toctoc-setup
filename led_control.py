import RPi.GPIO as GPIO
import time

# Configuration du mode de numérotation des pins (BCM)
GPIO.setmode(GPIO.BCM)

# Définition du numéro de pin GPIO
LED_PIN = 21

# Configuration de la pin en sortie
GPIO.setup(LED_PIN, GPIO.OUT)

try:
    while True:
        # Allumer la LED
        print("LED allumée")
        GPIO.output(LED_PIN, GPIO.HIGH)
        time.sleep(1)  # Attendre 1 seconde
        
        # Éteindre la LED
        print("LED éteinte")
        GPIO.output(LED_PIN, GPIO.LOW)
        time.sleep(1)  # Attendre 1 seconde

except KeyboardInterrupt:
    print("\nProgramme arrêté par l'utilisateur")

finally:
    # Nettoyage des ports GPIO
    GPIO.cleanup()