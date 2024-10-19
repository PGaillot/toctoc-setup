import sys
import RPi.GPIO as GPIO
import time

# Configuration des GPIO
LED_PIN = 18

def setup():
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(LED_PIN, GPIO.OUT)

def start_led():
    GPIO.output(LED_PIN, GPIO.HIGH)
    print("LED allumée")

def shutdown_led():
    GPIO.output(LED_PIN, GPIO.LOW)
    print("LED éteinte")

def cleanup():
    GPIO.cleanup()

if __name__ == "__main__":
    setup()
    if len(sys.argv) > 1 and sys.argv[1] == "on":
        allumer_led()
    elif len(sys.argv) > 1 and sys.argv[1] == "off":
        eteindre_led()
    else:
        print("Usage: python3 control_led.py [on|off]")
    cleanup()