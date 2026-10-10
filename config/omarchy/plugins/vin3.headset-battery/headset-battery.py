#!/usr/bin/env python3
"""Battery of the connected headsets, as JSON for the bar widget.

Two sources:
- Sony PULSE Elite / Explore through the PlayStation Link adapter (054c:0ecc).
  It isn't Bluetooth, so nothing in the system knows its battery; it comes
  from the adapter's HID feature report 0x82 (byte 1 = 1 while linked,
  byte 2 = 0x10/0x30 while on, 0x20 while shutting down, byte 3 = battery
  on a 0-15 scale). With the headset off the read fails with EPIPE.
  Protocol from github.com/Jprnp/pslink-libusb and
  github.com/klakiti/pulse-elite-autoswitch.
- Bluetooth headsets (the UGREEN on the notebook) through UPower, which
  gets their battery from BlueZ.
"""
import fcntl
import glob
import json
import os
import subprocess

PSLINK_ID = "054C:00000ECC"


def hidiocgfeature(length):
    return (3 << 30) | (length << 16) | (ord("H") << 8) | 0x07


def pslink_hidraw():
    for dev in glob.glob("/sys/class/hidraw/hidraw*"):
        try:
            with open(os.path.join(dev, "device/uevent")) as f:
                if PSLINK_ID in f.read().upper():
                    return "/dev/" + os.path.basename(dev)
        except OSError:
            continue
    return None


def pulse():
    path = pslink_hidraw()
    if not path:
        return None
    try:
        fd = os.open(path, os.O_RDWR | os.O_NONBLOCK)
    except PermissionError:
        return {"name": "Sony Pulse", "error": "sem permissão em " + path}
    except OSError:
        return None
    try:
        buf = bytearray(64)
        buf[0] = 0x82
        fcntl.ioctl(fd, hidiocgfeature(64), buf, True)
    except OSError:
        return None  # EPIPE: headset desligado
    finally:
        os.close(fd)
    if buf[1] != 1 or buf[2] not in (0x10, 0x30):
        return None
    level = min(buf[3], 15)
    return {"name": "Sony Pulse", "percent": round(level / 15 * 100), "detail": f"{level}/15"}


def bluetooth():
    try:
        out = subprocess.run(["upower", "-d"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        return []
    found = []
    for block in out.split("\n\n"):
        fields = {}
        kind = None
        for line in block.splitlines():
            line = line.strip()
            if line in ("headset", "headphones"):
                kind = line
            elif ":" in line:
                k, v = line.split(":", 1)
                fields[k.strip()] = v.strip()
        if not kind or "percentage" not in fields:
            continue
        try:
            pct = round(float(fields["percentage"].split("%")[0].replace(",", ".")))
        except ValueError:
            continue
        found.append({"name": fields.get("model") or "Headset", "percent": pct})
    return found


def main():
    headsets = bluetooth()
    p = pulse()
    if p:
        headsets.insert(0, p)
    print(json.dumps(headsets, ensure_ascii=False))


if __name__ == "__main__":
    main()
