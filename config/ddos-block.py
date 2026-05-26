#!/usr/bin/env python3
# ddos-block.py — Wazuh Active Response: Auto-block DDoS source IP
# Kelompok 6 MIKS ITS
# Dipanggil otomatis oleh Wazuh Manager saat rule DDoS terpicu

import sys
import json
import subprocess
import datetime

LOG_FILE = '/var/ossec/logs/active-responses.log'
INTERNAL_IPS = {'127.0.0.1', '10.0.0.5', '10.0.0.6', '10.0.0.7'}


def log(msg):
    ts = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a') as f:
        f.write(f'[{ts}] ddos-block: {msg}\n')


def is_blocked(ip):
    result = subprocess.run(
        ['iptables', '-C', 'INPUT', '-s', ip, '-j', 'DROP'],
        capture_output=True
    )
    return result.returncode == 0


def block(ip):
    if is_blocked(ip):
        log(f'ALREADY BLOCKED {ip}')
        return
    subprocess.run(['iptables', '-I', 'INPUT', '-s', ip, '-j', 'DROP'])
    subprocess.run(['iptables', '-I', 'FORWARD', '-s', ip, '-j', 'DROP'])
    log(f'BLOCKED {ip}')


def unblock(ip):
    subprocess.run(['iptables', '-D', 'INPUT', '-s', ip, '-j', 'DROP'])
    subprocess.run(['iptables', '-D', 'FORWARD', '-s', ip, '-j', 'DROP'])
    log(f'UNBLOCKED {ip}')


if __name__ == '__main__':
    try:
        data = json.loads(sys.stdin.readline())
        action = data.get('command', 'add')
        alert = data.get('parameters', {}).get('alert', {})
        src_ip = alert.get('data', {}).get('srcip', '')

        if not src_ip:
            src_ip = data.get('parameters', {}).get('agent', {}).get('ip', '')

        if src_ip and src_ip not in INTERNAL_IPS:
            if action == 'add':
                block(src_ip)
            elif action == 'delete':
                unblock(src_ip)
        else:
            log(f'SKIP: IP tidak valid atau IP internal: {src_ip}')

    except Exception as e:
        log(f'ERROR: {str(e)}')
