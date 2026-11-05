#!/usr/bin/env python3
"""Generate the documented ARRIS DUID-EN from a serial supplied on stdin."""
import argparse
import re
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--oui', default='001E46', help='Manufacturer OUI as six hex digits')
    args = parser.parse_args()
    serial = sys.stdin.read().strip()
    if not re.fullmatch(r'[A-Za-z0-9]{6,32}', serial):
        parser.error('Expected a gateway serial on stdin; the value is not echoed')
    if not re.fullmatch(r'[0-9A-Fa-f]{6}', args.oui):
        parser.error('OUI must contain six hex digits')
    duid = b'\x00\x02' + (3561).to_bytes(4, 'big')
    duid += (args.oui.upper() + '-' + serial).encode('ascii')
    print(duid.hex())


if __name__ == '__main__':
    main()
