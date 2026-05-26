# Kendala dan Solusi Deployment

## Kelompok 6 — MIKS ITS

### 1. Policy ITS Memblokir Azure CLI
**Kendala:** Policy subscription Azure for Students ITS memblokir pembuatan VNet, NSG, dan Public IP via Azure CLI di semua region.
**Solusi:** Deploy VM melalui Azure Portal (GUI) yang berhasil bypass policy CLI.

### 2. VM Size Tidak Tersedia
**Kendala:** Standard_B1s dan Standard_B2s tidak tersedia di region southeastasia (quota 0).
**Solusi:** Ganti ke size `Standard_B2as_v2` dan deploy via portal.

### 3. Zone Penuh
**Kendala:** Zone 1 di Southeast Asia penuh (ZonalAllocationFailed).
**Solusi:** Pindah ke Zone 2 yang berhasil.

### 4. Quota Public IP Habis
**Kendala:** Limit 3 Public IP, agent-db tidak bisa mendapat Public IP.
**Solusi:** Akses agent-db via wazuh-manager sebagai jump host.

### 5. Versi Wazuh Agent Tidak Kompatibel
**Kendala:** Wazuh Agent 4.14.5 (terbaru) tidak kompatibel dengan Manager 4.7.5.
**Solusi:** Install versi spesifik: `sudo apt install wazuh-agent=4.7.5-1 -y`

### 6. Ubuntu 24.04 Tidak Didukung
**Kendala:** Installer Wazuh 4.7 hanya mendukung Ubuntu 22.04 ke bawah.
**Solusi:** Gunakan flag `--ignore-check` pada semua langkah instalasi.

### 7. IP Attacker Ikut Terblokir
**Kendala:** Setelah simulasi DDoS, IP WSL ikut terblokir sehingga SSH ke agent-web timeout.
**Solusi:** Akses agent-web via jump host untuk verifikasi, atau reset manual:
```bash
ssh azureuser@52.237.92.40 "ssh azureuser@10.0.0.6 'sudo iptables -F INPUT'"
```
