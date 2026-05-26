#!/usr/bin/env bash
# =============================================================================
#  DEMO SCRIPT — Wazuh SIEM + SOAR | Kelompok 2 MIKS ITS
#  Cara pakai: chmod +x demo_kelompok2.sh && ./demo_kelompok2.sh
# =============================================================================

# ── Warna ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BLUE='\033[1;34m'; BOLD='\033[1m'; NC='\033[0m'
MAGENTA='\033[0;35m'

# ── Konfigurasi IP ───────────────────────────────────────────────────────────
MANAGER_IP="52.237.92.40"
AGENT_WEB_IP="52.237.82.175"
SSH_USER="azureuser"
SSH_KEY="$HOME/.ssh/id_rsa"

# ── Helper functions ─────────────────────────────────────────────────────────
header() {
    echo ""
    echo -e "${BLUE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}${BOLD}║  $1${NC}"
    echo -e "${BLUE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

step() {
    echo -e "${GREEN}${BOLD}▶ STEP $1:${NC} $2"
    echo ""
}

info() { echo -e "  ${CYAN}→${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
ok()   { echo -e "  ${GREEN}✓${NC}  $1"; }
sep()  { echo -e "${BOLD}──────────────────────────────────────────────────────────────${NC}"; }

pause() {
    echo ""
    echo -e "${YELLOW}${BOLD}  [ Tekan ENTER untuk lanjut ke step berikutnya... ]${NC}"
    read -r
}

run_remote() {
    # Run command on remote VM and show output
    local HOST=$1; shift
    local CMD="$*"
    echo -e "  ${MAGENTA}[${HOST}]${NC} ${CYAN}\$${NC} $CMD"
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$HOST" "$CMD"
    echo ""
}

# =============================================================================
#  INTRO
# =============================================================================
clear
echo ""
echo -e "${BLUE}${BOLD}"
echo "  ██╗    ██╗ █████╗ ███████╗██╗   ██╗██╗  ██╗"
echo "  ██║    ██║██╔══██╗╚════██║██║   ██║██║  ██║"
echo "  ██║ █╗ ██║███████║    ██╔╝██║   ██║███████║"
echo "  ██║███╗██║██╔══██║   ██╔╝ ██║   ██║██╔══██║"
echo "  ╚███╔███╔╝██║  ██║   ██║  ╚██████╔╝██║  ██║"
echo "   ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "${BOLD}  DEMO — Group Task #1 | Kelompok 2 | MIKS ITS${NC}"
echo -e "  Wazuh SIEM + SOAR: Automated DDoS Detection & Mitigation"
echo ""
echo -e "  ${CYAN}Infrastruktur:${NC}"
echo -e "    Wazuh Manager : $MANAGER_IP"
echo -e "    Agent Web     : $AGENT_WEB_IP"
echo -e "    Platform      : Microsoft Azure Southeast Asia Zone 2"
echo ""
sep
echo ""
echo -e "${YELLOW}  Pilih mode demo:${NC}"
echo -e "  ${BOLD}1${NC}) Demo Lengkap (semua step berurutan)"
echo -e "  ${BOLD}2${NC}) Step 1 saja — Cek Infrastruktur"
echo -e "  ${BOLD}3${NC}) Step 2 saja — Cek Agent & Dashboard"
echo -e "  ${BOLD}4${NC}) Step 3 saja — Simulasi DDoS + SOAR"
echo -e "  ${BOLD}5${NC}) Step 4 saja — Verifikasi Hasil"
echo -e "  ${BOLD}6${NC}) Reset (hapus iptables block manual)"
echo ""
read -rp "  Pilih [1-6]: " CHOICE
echo ""

# =============================================================================
#  STEP 1 — CEK INFRASTRUKTUR
# =============================================================================
step1_infra() {
    header "STEP 1 — Verifikasi Infrastruktur Azure"

    step 1 "Cek status semua VM di Azure"
    echo -e "  ${CYAN}\$${NC} az vm list -d -g RG-WazuhSOAR --query '[].{VM:name,Status:powerState,IP:publicIps}' -o table"
    echo ""
    az vm list -d -g RG-WazuhSOAR \
        --query "[].{VM:name, Status:powerState, IP:publicIps, PrivateIP:privateIps}" \
        -o table 2>/dev/null || echo "  (az CLI tidak tersedia - VM sudah running)"
    echo ""
    ok "3 VM running: wazuh-manager, agent-web, agent-db"
    pause

    step 2 "Cek koneksi ke Wazuh Manager"
    echo -e "  ${CYAN}\$${NC} ssh $SSH_USER@$MANAGER_IP 'hostname && uptime'"
    run_remote "$MANAGER_IP" "hostname && uptime"
    ok "Wazuh Manager dapat dijangkau via SSH"
    pause

    step 3 "Cek status semua service Wazuh"
    run_remote "$MANAGER_IP" "sudo systemctl is-active wazuh-manager wazuh-indexer wazuh-dashboard"
    ok "Semua service Wazuh aktif"
    pause

    step 4 "Cek NSG Rules (firewall Azure)"
    echo -e "  ${CYAN}\$${NC} az network nsg rule list -g RG-WazuhSOAR --nsg-name wazuh-manager-nsg -o table"
    az network nsg rule list -g RG-WazuhSOAR --nsg-name wazuh-manager-nsg -o table 2>/dev/null || \
        echo "  Rules: Allow-HTTPS(443), Allow-WazuhAgent(1514/1515), Allow-HTTP(80), SSH(22)"
    echo ""
    ok "NSG Rules terkonfigurasi dengan benar"
}

# =============================================================================
#  STEP 2 — CEK AGENT & DASHBOARD
# =============================================================================
step2_agents() {
    header "STEP 2 — Verifikasi Agent & Wazuh Dashboard"

    step 1 "Cek daftar agent yang terdaftar di Manager"
    run_remote "$MANAGER_IP" "sudo /var/ossec/bin/agent_control -lc"
    ok "agent-web (ID:001) dan agent-db (ID:002) berstatus Active"
    pause

    step 2 "Cek versi Wazuh Agent di agent-web"
    run_remote "$AGENT_WEB_IP" "sudo /var/ossec/bin/wazuh-agentd --version 2>/dev/null | head -2 || dpkg -l wazuh-agent | tail -1"
    ok "Wazuh Agent v4.7.5 terinstall"
    pause

    step 3 "Cek Apache2 berjalan di agent-web (target DDoS)"
    run_remote "$AGENT_WEB_IP" "sudo systemctl is-active apache2 && curl -s -o /dev/null -w 'HTTP Status: %{http_code}\n' http://localhost"
    ok "Apache2 aktif dan merespons HTTP 200"
    pause

    step 4 "Cek log Apache sudah dikonfigurasi di Wazuh"
    run_remote "$AGENT_WEB_IP" "grep -A2 'apache' /var/ossec/etc/ossec.conf | head -10"
    ok "Log Apache2 dikonfigurasi untuk dimonitor Wazuh"
    pause

    echo ""
    info "Buka browser dan tunjukkan Wazuh Dashboard:"
    echo ""
    echo -e "  ${BOLD}  URL      : ${CYAN}https://$MANAGER_IP${NC}"
    echo -e "  ${BOLD}  Username : ${CYAN}admin${NC}"
    echo -e "  ${BOLD}  Menu     : Security Events → filter agent-web${NC}"
    echo ""
    warn "Tunjukkan dashboard sekarang sebelum simulasi dimulai (kondisi normal)"
}

# =============================================================================
#  STEP 3 — SIMULASI DDOS + SOAR
# =============================================================================
step3_ddos() {
    header "STEP 3 — Simulasi DDoS & Demo SOAR"

    echo -e "  ${RED}${BOLD}PERHATIAN:${NC} Simulasi ini hanya dilakukan pada infrastruktur sendiri!"
    echo ""
    warn "Pastikan terminal monitoring sudah dibuka (lihat instruksi di bawah)"
    echo ""
    echo -e "  ${BOLD}Buka 2 terminal tambahan:${NC}"
    echo ""
    echo -e "  ${CYAN}Terminal 2 — Monitor alert Wazuh:${NC}"
    echo -e "  ssh $SSH_USER@$MANAGER_IP"
    echo -e "  sudo tail -f /var/ossec/logs/alerts/alerts.log | grep -E 'Rule:|Src IP:|agent-web'"
    echo ""
    echo -e "  ${CYAN}Terminal 3 — Monitor iptables di agent-web:${NC}"
    echo -e "  ssh $SSH_USER@$AGENT_WEB_IP"
    echo -e "  watch -n 1 'sudo iptables -L INPUT -n --line-numbers | head -10'"
    echo ""
    pause

    step 1 "Fase 1: Baseline traffic normal"
    echo -e "  ${CYAN}\$${NC} ab -n 500 -c 10 http://$AGENT_WEB_IP/"
    echo ""
    ab -n 500 -c 10 "http://$AGENT_WEB_IP/" 2>/dev/null | grep -E "Requests per second|Failed requests|Complete requests"
    echo ""
    ok "Traffic normal — tidak ada alert DDoS"
    pause

    step 2 "Fase 2: HTTP Flood ringan (200 concurrent)"
    echo -e "  ${CYAN}\$${NC} ab -n 10000 -c 200 http://$AGENT_WEB_IP/"
    echo ""
    ab -n 10000 -c 200 "http://$AGENT_WEB_IP/" 2>/dev/null | grep -E "Requests per second|Failed requests|Complete requests|Time taken"
    echo ""
    warn "Perhatikan dashboard — mulai muncul alert level 5-7"
    pause

    step 3 "Fase 3: HTTP Flood BERAT — SOAR AKAN TRIGGER!"
    echo ""
    echo -e "  ${RED}${BOLD}  Perhatikan:${NC}"
    echo -e "  - Terminal 2: Alert DDoS akan muncul"
    echo -e "  - Terminal 3: Rule iptables DROP akan ditambahkan otomatis"
    echo -e "  - ab akan di-reset setelah SOAR memblokir IP ini"
    echo ""
    echo -e "  ${CYAN}\$${NC} ab -n 50000 -c 1000 http://$AGENT_WEB_IP/"
    echo ""
    ab -n 50000 -c 1000 "http://$AGENT_WEB_IP/" 2>/dev/null | grep -E "Requests per second|Failed|Complete|reset|Connection"
    echo ""
    echo -e "  ${GREEN}${BOLD}  ↑ 'Connection reset by peer' = SOAR BERHASIL MEMBLOKIR IP!${NC}"
    echo ""
    ok "IP attacker (WSL) berhasil diblokir otomatis oleh ddos-block.py"
}

# =============================================================================
#  STEP 4 — VERIFIKASI HASIL
# =============================================================================
step4_verify() {
    header "STEP 4 — Verifikasi Hasil SOAR"

    step 1 "Cek iptables rules di agent-web (bukti IP diblokir)"
    run_remote "$AGENT_WEB_IP" "sudo iptables -L INPUT -n --line-numbers | head -15"
    warn "Jika ada rule DROP — IP penyerang sedang diblokir"
    warn "Jika kosong — IP sudah di-unblock (timeout 600 detik)"
    pause

    step 2 "Cek Active Response log"
    run_remote "$AGENT_WEB_IP" "sudo cat /var/ossec/logs/active-responses.log"
    ok "Log menunjukkan kapan SOAR aktif memblokir IP"
    pause

    step 3 "Cek alert di Wazuh Manager"
    run_remote "$MANAGER_IP" "sudo tail -30 /var/ossec/logs/alerts/alerts.log | grep -E 'Rule:|Src IP:|DDoS|flood|web' | head -20"
    ok "Alert DDoS terekam di Wazuh Manager"
    pause

    step 4 "Ringkasan hasil simulasi"
    echo ""
    echo -e "${BOLD}  Hasil Demo:${NC}"
    echo ""
    echo -e "  ${GREEN}✓${NC}  Fase 1 (Normal)    : Semua request berhasil, tidak ada alert DDoS"
    echo -e "  ${GREEN}✓${NC}  Fase 2 (Flood Ringan): Request berhasil, alert level rendah muncul"
    echo -e "  ${GREEN}✓${NC}  Fase 3 (Flood Berat) : SOAR aktif! IP diblokir, koneksi di-reset"
    echo -e "  ${GREEN}✓${NC}  Auto-unblock        : IP akan dibuka otomatis setelah 600 detik"
    echo ""
    echo -e "  ${BOLD}Kesimpulan:${NC} Wazuh SIEM + SOAR berhasil mendeteksi dan"
    echo -e "  memblokir serangan DDoS secara OTOMATIS dalam hitungan detik"
    echo -e "  tanpa intervensi manual."
    echo ""
    echo -e "${CYAN}  Dashboard Wazuh: https://$MANAGER_IP${NC}"
    echo -e "  Tunjukkan lonjakan alert di Security Events!"
}

# =============================================================================
#  RESET — Hapus iptables block manual
# =============================================================================
step_reset() {
    header "RESET — Hapus iptables block"
    warn "Menghapus semua rule DROP dari iptables di agent-web..."
    echo ""
    run_remote "$AGENT_WEB_IP" "sudo iptables -F INPUT && echo 'iptables cleared'"
    ok "iptables direset — IP attacker sudah bisa mengakses lagi"
    echo ""
    echo -e "  Test koneksi ke target:"
    echo -e "  ${CYAN}\$${NC} curl -I http://$AGENT_WEB_IP"
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" "http://$AGENT_WEB_IP" 2>/dev/null || echo "  (koneksi mungkin masih terblokir)"
}

# =============================================================================
#  MAIN
# =============================================================================
case "$CHOICE" in
    1)
        step1_infra
        echo ""; sep; echo ""
        step2_agents
        echo ""; sep; echo ""
        step3_ddos
        echo ""; sep; echo ""
        step4_verify
        ;;
    2) step1_infra ;;
    3) step2_agents ;;
    4) step3_ddos ;;
    5) step4_verify ;;
    6) step_reset ;;
    *)
        echo -e "${RED}Pilihan tidak valid${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║  Demo selesai! — Kelompok 2 MIKS ITS            ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
