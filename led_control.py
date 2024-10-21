#!/usr/bin/env python3
import threading
import time
from gpiozero import LED

led = LED(17)
led_state = None
current_thread = None

def cancel_previous_effect():
    global current_thread
    if current_thread and current_thread.is_alive():
        current_thread.do_run = False
        current_thread.join()  # Attendre que le thread actuel se termine

def set_fixed_light():
    global led_state
    cancel_previous_effect()
    led_state = "fixed"
    led.on()

def set_blinking_light():
    global led_state, current_thread
    cancel_previous_effect()
    led_state = "blinking"
    
    def blinking():
        t = threading.currentThread()
        while getattr(t, "do_run", True):
            led.on()
            time.sleep(1)
            led.off()
            time.sleep(1)
    
    current_thread = threading.Thread(target=blinking)
    current_thread.start()

def set_fast_blinking_light():
    global led_state, current_thread
    cancel_previous_effect()
    led_state = "fast_blinking"
    
    def fast_blinking():
        t = threading.currentThread()
        while getattr(t, "do_run", True):
            led.on()
            time.sleep(0.2)
            led.off()
            time.sleep(0.2)
    
    current_thread = threading.Thread(target=fast_blinking)
    current_thread.start()
