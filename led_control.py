#!/usr/bin/env python3
import threading
import time
from gpiozero import LED

class LEDControl:
    def __init__(self):
        self.led = LED(17)
        self.current_thread = None

    def stop_current_pattern(self):
        """Arrête le pattern LED actuel s'il existe"""
        if self.current_thread and self.current_thread.is_alive():
            self.current_thread.do_run = False
            self.current_thread.join()
            
    def installation_start(self):
        """LED clignote rapidement - début du script"""
        self.stop_current_pattern()
        
        def pattern():
            thread = threading.current_thread()
            while getattr(thread, "do_run", True):
                self.led.on()
                time.sleep(0.2)
                self.led.off()
                time.sleep(0.2)
                
        self.current_thread = threading.Thread(target=pattern)
        self.current_thread.start()
        
    def error(self):
        """LED clignote lentement - une erreur est survenue"""
        self.stop_current_pattern()
        
        def pattern():
            thread = threading.current_thread()
            while getattr(thread, "do_run", True):
                self.led.on()
                time.sleep(1)
                self.led.off()
                time.sleep(1)
                
        self.current_thread = threading.Thread(target=pattern)
        self.current_thread.start()
        
    def success(self):
        """LED reste allumée - tout s'est bien passé"""
        self.stop_current_pattern()
        self.led.on()
        
    def cleanup(self):
        """Éteint la LED et nettoie"""
        self.stop_current_pattern()
        self.led.off()

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python3 led_control.py [start|error|success|off]")
        sys.exit(1)
        
    led = LEDControl()
    
    command = sys.argv[1]
    if command == "start":
        led.installation_start()
    elif command == "error":
        led.error()
    elif command == "success":
        led.success()
    elif command == "off":
        led.cleanup()