# Wazuh SIEM + SOAR — Group Task #1

**Kelompok 6 | Manajemen Insiden Keamanan Siber (MIKS)**
**Institut Teknologi Sepuluh Nopember (ITS)**

## Anggota Kelompok

| Nama | NRP | Tugas |
|------|-----|-------|
| Muhammad Farrel Rafli Al Fasya | 5027241075 | Azure Infrastructure Setup, Wazuh Manager Installation, Laporan |
| Mohammad Abyan Ranuaji | 5027241106 | Wazuh Agent Configuration, SOAR Implementation |
| Ari | - | DDoS Simulation & Testing, Alert Analysis, Demo |

## Deskripsi Proyek

Implementasi **Wazuh SIEM** (Security Information and Event Management) dengan integrasi **SOAR** (Security Orchestration, Automation and Response) untuk deteksi dan mitigasi otomatis serangan **DDoS** (Distributed Denial of Service).

## Arsitektur

```
┌─────────────────────────────────────────────────┐
│         Azure Virtual Network (10.0.0.0/16)     │
│                                                 │
│  [wazuh-manager]  10.0.0.5  52.237.92.40       │
│  [agent-web]      10.0.0.6  52.237.82.175      │
│  [agent-db]       10.0.0.7  (no public IP)     │
│                                                 │
│  Region: Southeast Asia | Zone: 2               │
└─────────────────────────────────────────────────┘
```

## Spesifikasi

| Komponen | Detail |
|----------|--------|
| Platform | Microsoft Azure Student Free Tier |
| Region | Southeast Asia, Zone 2 |
| VM Size | Standard_B2as_v2 (2 vCPU, 8 GiB RAM) |
| OS | Ubuntu Server 24.04 LTS |
| SIEM | Wazuh 4.7.5 |
| SOAR | Wazuh Active Response + Python Script |

## Alur Kerja SOAR

```
Log Apache → Wazuh Agent → Wazuh Manager
                               ↓
                        Analisis Rule DDoS
                               ↓
                    Alert Level >= 10 Terpicu
                               ↓
                   Active Response Dijalankan
                               ↓
                  ddos-block.py → iptables DROP
                               ↓
                  Auto-unblock setelah 600 detik
```

## Hasil

- Total alert terdeteksi: **1.429 events** dalam 24 jam
- Serangan nyata dari internet berhasil diblokir otomatis
- SOAR response time: **< 20 detik** dari deteksi ke blokir
- Auto-unblock berjalan setelah **600 detik**

## Cara Menjalankan Demo

```bash
chmod +x scripts/demo_kelompok6.sh
./scripts/demo_kelompok6.sh
```

## Struktur Repository

```
.
├── README.md
├── scripts/
│   ├── demo_kelompok6.sh        # Script demo otomatis
│   └── panduan_teknis.sh        # Panduan teknis step-by-step
├── config/
│   ├── ddos-block.py            # Script SOAR Active Response
│   ├── local_rules.xml          # Custom Wazuh rules DDoS
│   └── ossec_active_response.conf  # Konfigurasi Active Response
└── docs/
    └── kendala_dan_solusi.md    # Dokumentasi kendala deployment
```

## Referensi

- [Wazuh Documentation](https://documentation.wazuh.com)
- [Azure for Students](https://azure.microsoft.com/id-id/free/students/)
- [MITRE ATT&CK T1499](https://attack.mitre.org/techniques/T1499/)
