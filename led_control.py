#!/usr/bin/env python3
from gpiozero import LED
import time

# Configuration de la LED (GPIO 21)
led = LED(21)

try:
    while True:
        # Allumer la LED
        led.on()
        time.sleep(1)  # Attendre 1 seconde
        
        # Éteindre la LED
        led.off()
        time.sleep(1)  # Attendre 1 seconde

except KeyboardInterrupt:
    print("\nProgramme arrêté par l'utilisateur")

finally:
    # Nettoyage des ressources GPIO (automatique avec gpiozero)
    print("Nettoyage terminé")