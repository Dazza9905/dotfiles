#!/usr/bin/env python3
import argparse
import requests
import sys
import tty
import termios

def send_gcode(ip, key, gcode):
    try:
        r = requests.post(
            f"http://{ip}/api/v1/printer/gcode",
            headers={"Content-Type": "application/json", "X-Api-Key": key},
            json={"gcode": gcode},
            timeout=3,
        )
        r.raise_for_status()
    except requests.RequestException as e:
        print(f"Error: {e}")

def move(ip, key, axis, dist):
    send_gcode(ip, key, f"G91\nG1 {axis}{dist:+.1f} F300\nG90")

def getch():
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        return sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

KEYMAP = {
    "a": ("X", -0.1),
    "d": ("X", +0.1),
    "w": ("Y", +0.1),
    "s": ("Y", -0.1),
    "r": ("Z", +0.1),
    "f": ("Z", -0.1),
}

def main():
    parser = argparse.ArgumentParser(description="Prusa Link wireless jog controller")
    parser.add_argument("-ip", required=True, help="Printer IP address")
    parser.add_argument("-key", required=True, help="Prusa Link API key")
    args = parser.parse_args()

    print("Jog controller — WASD=XY  R/F=Z  0.1mm steps  Q=quit")

    while True:
        ch = getch().lower()
        if ch == "q":
            print("\nExiting.")
            break
        if ch in KEYMAP:
            axis, dist = KEYMAP[ch]
            print(f"Moving {axis} {dist:+.1f}mm")
            move(args.ip, args.key, axis, dist)

if __name__ == "__main__":
    main()
