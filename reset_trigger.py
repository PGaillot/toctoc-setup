#!/usr/bin/env python3
from gpiozero import Button
import subprocess
from signal import pause

button = Button(21, hold_time=3)

def button_held():
    print("Bouton maintenu pendant 3 secondes ! Exécution du script...")
    subprocess.run(["/bin/bash", "/home/toctoc/toctoc-setup/reset.sh"])

button.when_held = button_held


print("Attente de l'appui long sur le bouton (3s) pour reset...")
pause()