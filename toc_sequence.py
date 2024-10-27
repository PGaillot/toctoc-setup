#!/usr/bin/env python3

import RPi.GPIO as GPIO
import time

# Configurer le GPIO
SENSOR_PIN = 17  # Numéro de la broche où DO est connecté
GPIO.setmode(GPIO.BCM)
GPIO.setup(SENSOR_PIN, GPIO.IN)

def detect_vibrations():
    sequence = []
    print("Prêt à détecter les frappes...")
    try:
        while True:
            if GPIO.input(SENSOR_PIN) == GPIO.HIGH:
                timestamp = time.time()  # Capturer le moment exact de la frappe
                sequence.append(timestamp)
                print(f"Frappe détectée à {timestamp}")
                time.sleep(0.1)  # Petite pause pour éviter les détections multiples
    except KeyboardInterrupt:
        GPIO.cleanup()  # Nettoyer les GPIO après l'arrêt

    # Afficher la séquence de frappes
    print("Séquence de frappes:", sequence)

detect_vibrations()