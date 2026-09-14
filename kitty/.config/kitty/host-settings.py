#!/usr/bin/env python3
import socket


font_sizes = {
    "caspian": 14.0,
}

hostname = socket.gethostname()
font_size = font_sizes.get(hostname, 11.0)

print(f"font_size {font_size}")
