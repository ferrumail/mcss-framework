# Mappatura Evidenze

Questo documento descrive la correlazione tra i file prodotti da `mailserver-audit-collect.sh` e i controlli MCSS.

## Struttura Output Script

```
mailaudit_hostname_timestamp/
├── 00_summary.txt
├── postfix/
│   ├── version.txt
│   ├── package_info.txt
│   ├── queue_status.txt
│   ├── config_files/
│   │   ├── main.cf
│   │   ├── master.cf
│   │   └── ...
│   └── config_active/
│       ├── postconf_n.txt
│       ├── postconf_full.txt
│       ├── master_cf_active.txt
│       ├── tls_config.txt
│       └── sasl_config.txt
├── exim/
│   └── ...
├── dovecot/
│   └── ...
├── cyrus/
│   └── ...
├── antispam/
│   └── ...
├── antivirus/
│   └── ...
├── dkim/
│   └── ...
├── dmarc/
│   └── ...
├── spf/
│   └── ...
├── firewall/
│   └── ...
├── mac/
│   └── ...
├── fail2ban/
│   └── ...
├── policy/
│   └── ...
├── tls/
│   └── ...
├── aliases/
│   └── ...
├── timestamps/
│   └── ...
├── logs/
│   └── ...
└── system/
    └── ...
```

## Mappatura per Area

### MTA — Postfix

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| POSTFIX-001 | `postfix/version.txt` | Numero versione, confronto con EOL |
| POSTFIX-002 | `postfix/config_active/postconf_n.txt` | `smtpd_banner` |
| POSTFIX-003 | `postfix/config_active/postconf_n.txt` | `mynetworks` — deve essere restrittivo |
| POSTFIX-004 | `postfix/config_active/postconf_n.txt` | `smtpd_relay_restrictions` |
| POSTFIX-005 | `postfix/config_active/postconf_n.txt` | `smtpd_recipient_restrictions` |
| POSTFIX-006 | `postfix/config_active/postconf_n.txt` | `smtpd_helo_required = yes` |
| POSTFIX-007 | `postfix/config_active/postconf_n.txt` | `strict_rfc821_envelopes` |
| POSTFIX-008 | `postfix/config_active/postconf_n.txt` | `disable_vrfy_command = yes` |
| POSTFIX-009 | `postfix/config_active/postconf_n.txt` | `smtpd_delay_reject` |
| POSTFIX-010 | `postfix/config_active/postconf_n.txt` | `message_size_limit` |
| POSTFIX-011 | `postfix/config_active/postconf_n.txt` | `mailbox_size_limit` |
| POSTFIX-012 | `postfix/config_active/postconf_n.txt` | `smtpd_client_restrictions` |
| POSTFIX-013 | `postfix/config_active/postconf_n.txt` | `smtpd_error_sleep_time` |
| POSTFIX-014 | `postfix/config_active/postconf_n.txt` | `smtpd_hard_error_limit` |
| POSTFIX-015 | `postfix/queue_status.txt` | Numero messaggi in coda |
| POSTFIX-016 | `system/services.txt` | Stato servizio postfix |
| POSTFIX-017 | `postfix/config_lint.txt` | Output `postfix check` |
| POSTFIX-018 | `postfix/config_active/master_cf_active.txt` | Submission su porta 587 |

### MTA — Exim

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| EXIM-001 | `exim/version.txt` | Versione, build info |
| EXIM-002 | `exim/config_active/exim_bP.txt` | `smtp_banner` |
| EXIM-003 | `exim/config_active/exim_bP.txt` | `host_lookup` |
| EXIM-004 | `exim/security/acl_summary.txt` | `acl_smtp_rcpt` definito |
| EXIM-005 | `exim/security/acl_summary.txt` | `acl_smtp_data` definito |
| EXIM-006 | `exim/security/acl_summary.txt` | `verify = recipient` |
| EXIM-007 | `exim/security/acl_summary.txt` | Verifica HELO in ACL |
| EXIM-008 | `exim/config_active/exim_bP.txt` | `message_size_limit` |
| EXIM-009 | `exim/security/ratelimit_config.txt` | `smtp_accept_max` |
| EXIM-010 | `exim/security/ratelimit_config.txt` | `smtp_accept_max_per_host` |
| EXIM-011 | `exim/security/ratelimit_config.txt` | `ratelimit` in ACL |
| EXIM-012 | `exim/security/dkim_config.txt` | `dkim_domain`, `dkim_selector` |
| EXIM-013 | `exim/security/spf_config.txt` | SPF check in ACL |
| EXIM-014 | `exim/security/content_scanning.txt` | `av_scanner` |
| EXIM-015 | `exim/security/content_scanning.txt` | `spamd_address` |
| EXIM-016 | `exim/queue_status.txt` | `exim -bp` output |
| EXIM-017 | `system/services.txt` | Stato servizio exim |
| EXIM-018 | `exim/config_test.txt` | Errori configurazione |

### MDA — Dovecot

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| DOVECOT-001 | `dovecot/version.txt` | Versione |
| DOVECOT-002 | `dovecot/config_active/doveconf_n.txt` | `ssl = required` |
| DOVECOT-003 | `dovecot/config_active/doveconf_n.txt` | `ssl_min_protocol` |
| DOVECOT-004 | `dovecot/config_active/doveconf_n.txt` | `ssl_prefer_server_ciphers` |
| DOVECOT-005 | `dovecot/config_active/doveconf_n.txt` | `ssl_cipher_list` |
| DOVECOT-006 | `dovecot/config_active/doveconf_n.txt` | `disable_plaintext_auth` |
| DOVECOT-007 | `dovecot/config_active/doveconf_n.txt` | `auth_mechanisms` |
| DOVECOT-008 | `dovecot/config_active/doveconf_n.txt` | `login_greeting` |
| DOVECOT-009 | `dovecot/config_active/protocols.txt` | Protocolli abilitati |
| DOVECOT-010 | `dovecot/config_active/listeners.txt` | Porte in ascolto |
| DOVECOT-011 | `dovecot/config_active/doveconf_n.txt` | `auth_verbose_passwords` |
| DOVECOT-012 | `dovecot/config_active/doveconf_n.txt` | `log_path` |
| DOVECOT-013 | `dovecot/config_errors.txt` | Errori da doveconf |
| DOVECOT-014 | `system/services.txt` | Stato servizio |
| DOVECOT-015 | `dovecot/config_active/doveconf_N.txt` | Plugin quota |
| DOVECOT-016 | `dovecot/config_active/doveconf_P.txt` | `auth_cache_size` |

### TLS / Certificati

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| TLS-001 | `tls/*_info.txt` | `notAfter` > oggi |
| TLS-002 | `tls/*_info.txt` | `notAfter` > oggi + 30gg |
| TLS-003 | `tls/*_info.txt` | `notAfter` > oggi + 90gg |
| TLS-004 | `tls/*_info.txt` | Issuer non self-signed |
| TLS-005 | `tls/*_info.txt` | SAN include tutti i domini |
| TLS-006 | `tls/*_info.txt` | RSA >= 2048 bit |
| TLS-007 | `tls/*_info.txt` | Signature Algorithm no SHA1 |
| TLS-008 | `tls/*_info.txt` | Chain completa |
| TLS-009 | `postfix/config_active/postconf_n.txt` | `smtpd_tls_security_level` |
| TLS-010 | `postfix/config_active/postconf_n.txt` | `smtp_tls_security_level` |
| TLS-011 | `dovecot/config_active/ssl_config.txt` | `ssl_min_protocol` |
| TLS-012 | `dovecot/config_active/ssl_config.txt` | No RC4, DES, MD5 |

### Firewall

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| FIREWALL-001 | `firewall/type.txt` | Tipo firewall attivo |
| FIREWALL-002 | `firewall/*_mail.txt` | Regole porta 25 |
| FIREWALL-003 | `firewall/*_mail.txt` | Porte 110, 143 chiuse/limitate |
| FIREWALL-004 | `firewall/*_mail.txt` | Porte 993, 995, 465, 587 aperte |
| FIREWALL-005 | `firewall/*_mail.txt` | Porta 4190 (ManageSieve) |
| FIREWALL-006 | `firewall/*_full.txt` | Rate limiting rules |
| FIREWALL-007 | `firewall/ip6tables_mail.txt` | Regole IPv6 |
| FIREWALL-008 | `firewall/` | Coerenza con servizi |

### MAC (SELinux/AppArmor)

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| MAC-001 | `mac/type.txt` | Tipo MAC attivo |
| MAC-002 | `mac/selinux_status.txt` | `Enforcing` |
| MAC-003 | `mac/apparmor_status.txt` | `enabled` |
| MAC-004 | `mac/apparmor_enforcement.txt` | Profili in enforce |
| MAC-005 | `mac/selinux_booleans_mail.txt` | Booleani mail |
| MAC-006 | `mac/selinux_contexts.txt` | Processi confinati |
| MAC-007 | `mac/selinux_avc_denials.txt` | No denial recenti |
| MAC-008 | `mac/apparmor_violations.txt` | No violazioni recenti |
| MAC-009 | `mac/selinux_ports.txt` | Porte etichettate |

### Logging

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| LOGGING-001 | `postfix/config_active/postconf_n.txt` | Logging configurato |
| LOGGING-002 | `dovecot/config_active/doveconf_n.txt` | `log_path` |
| LOGGING-003 | Config files | syslog facility |
| LOGGING-004 | `logs/critical_events_stats.txt` | Conteggio errori |
| LOGGING-005 | `logs/top_failed_auth_ips.txt` | Pattern auth failure |
| LOGGING-006 | `logs/` | Presenza file ruotati |

### Storage

| Control ID | File Evidenza | Cosa Cercare |
|------------|---------------|--------------|
| STORAGE-001 | `system/partitions_mail.txt` | /var/mail separato |
| STORAGE-002 | `system/partitions_mail.txt` | /var/spool separato |
| STORAGE-003 | `system/partitions_mail.txt` | Spazio disponibile > 20% |
| STORAGE-004 | `system/partitions_mail.txt` | Quote filesystem |
| STORAGE-005 | `system/partitions_mail.txt` | Mount options |

## Pattern di Verifica

### Verifica positiva (valore deve essere presente)

```bash
grep -q "smtpd_helo_required = yes" postconf_n.txt && echo "PASS"
```

### Verifica negativa (valore deve essere assente)

```bash
grep -q "0.0.0.0/0" postconf_n.txt && echo "FAIL: open relay"
```

### Verifica range

```bash
value=$(grep message_size_limit postconf_n.txt | cut -d= -f2)
[ "$value" -gt 0 ] && [ "$value" -lt 52428800 ] && echo "PASS"
```

### Verifica confronto date

```bash
expiry=$(openssl x509 -in cert.pem -noout -enddate | cut -d= -f2)
expiry_epoch=$(date -d "$expiry" +%s)
now_epoch=$(date +%s)
days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
[ "$days_left" -gt 30 ] && echo "PASS"
```

## Note

- I path sono relativi alla directory di output dello script
- Alcuni controlli richiedono correlazione tra più file
- La verifica automatica copre ~65% dei controlli; il resto richiede analisi manuale o interviste
