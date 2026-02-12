# Evidence Mapping

This document describes the correlation between files produced by `mailserver-audit-collect.sh` and MCSS controls.

## Script Output Structure

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

## Mapping by Area

### MTA — Postfix

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| POSTFIX-001 | `postfix/version.txt` | Version number, compare with EOL |
| POSTFIX-002 | `postfix/config_active/postconf_n.txt` | `smtpd_banner` |
| POSTFIX-003 | `postfix/config_active/postconf_n.txt` | `mynetworks` — must be restrictive |
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
| POSTFIX-015 | `postfix/queue_status.txt` | Number of messages in queue |
| POSTFIX-016 | `system/services.txt` | Postfix service status |
| POSTFIX-017 | `postfix/config_lint.txt` | `postfix check` output |
| POSTFIX-018 | `postfix/config_active/master_cf_active.txt` | Submission on port 587 |

### MTA — Exim

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| EXIM-001 | `exim/version.txt` | Version, build info |
| EXIM-002 | `exim/config_active/exim_bP.txt` | `smtp_banner` |
| EXIM-003 | `exim/config_active/exim_bP.txt` | `host_lookup` |
| EXIM-004 | `exim/security/acl_summary.txt` | `acl_smtp_rcpt` defined |
| EXIM-005 | `exim/security/acl_summary.txt` | `acl_smtp_data` defined |
| EXIM-006 | `exim/security/acl_summary.txt` | `verify = recipient` |
| EXIM-007 | `exim/security/acl_summary.txt` | HELO verification in ACL |
| EXIM-008 | `exim/config_active/exim_bP.txt` | `message_size_limit` |
| EXIM-009 | `exim/security/ratelimit_config.txt` | `smtp_accept_max` |
| EXIM-010 | `exim/security/ratelimit_config.txt` | `smtp_accept_max_per_host` |
| EXIM-011 | `exim/security/ratelimit_config.txt` | `ratelimit` in ACL |
| EXIM-012 | `exim/security/dkim_config.txt` | `dkim_domain`, `dkim_selector` |
| EXIM-013 | `exim/security/spf_config.txt` | SPF check in ACL |
| EXIM-014 | `exim/security/content_scanning.txt` | `av_scanner` |
| EXIM-015 | `exim/security/content_scanning.txt` | `spamd_address` |
| EXIM-016 | `exim/queue_status.txt` | `exim -bp` output |
| EXIM-017 | `system/services.txt` | Exim service status |
| EXIM-018 | `exim/config_test.txt` | Configuration errors |

### MDA — Dovecot

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| DOVECOT-001 | `dovecot/version.txt` | Version |
| DOVECOT-002 | `dovecot/config_active/doveconf_n.txt` | `ssl = required` |
| DOVECOT-003 | `dovecot/config_active/doveconf_n.txt` | `ssl_min_protocol` |
| DOVECOT-004 | `dovecot/config_active/doveconf_n.txt` | `ssl_prefer_server_ciphers` |
| DOVECOT-005 | `dovecot/config_active/doveconf_n.txt` | `ssl_cipher_list` |
| DOVECOT-006 | `dovecot/config_active/doveconf_n.txt` | `disable_plaintext_auth` |
| DOVECOT-007 | `dovecot/config_active/doveconf_n.txt` | `auth_mechanisms` |
| DOVECOT-008 | `dovecot/config_active/doveconf_n.txt` | `login_greeting` |
| DOVECOT-009 | `dovecot/config_active/protocols.txt` | Enabled protocols |
| DOVECOT-010 | `dovecot/config_active/listeners.txt` | Listening ports |
| DOVECOT-011 | `dovecot/config_active/doveconf_n.txt` | `auth_verbose_passwords` |
| DOVECOT-012 | `dovecot/config_active/doveconf_n.txt` | `log_path` |
| DOVECOT-013 | `dovecot/config_errors.txt` | Errors from doveconf |
| DOVECOT-014 | `system/services.txt` | Service status |
| DOVECOT-015 | `dovecot/config_active/doveconf_N.txt` | Quota plugin |
| DOVECOT-016 | `dovecot/config_active/doveconf_P.txt` | `auth_cache_size` |

### TLS / Certificates

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| TLS-001 | `tls/*_info.txt` | `notAfter` > today |
| TLS-002 | `tls/*_info.txt` | `notAfter` > today + 30 days |
| TLS-003 | `tls/*_info.txt` | `notAfter` > today + 90 days |
| TLS-004 | `tls/*_info.txt` | Issuer not self-signed |
| TLS-005 | `tls/*_info.txt` | SAN includes all domains |
| TLS-006 | `tls/*_info.txt` | RSA >= 2048 bit |
| TLS-007 | `tls/*_info.txt` | Signature Algorithm no SHA1 |
| TLS-008 | `tls/*_info.txt` | Complete chain |
| TLS-009 | `postfix/config_active/postconf_n.txt` | `smtpd_tls_security_level` |
| TLS-010 | `postfix/config_active/postconf_n.txt` | `smtp_tls_security_level` |
| TLS-011 | `dovecot/config_active/ssl_config.txt` | `ssl_min_protocol` |
| TLS-012 | `dovecot/config_active/ssl_config.txt` | No RC4, DES, MD5 |

### Firewall

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| FIREWALL-001 | `firewall/type.txt` | Active firewall type |
| FIREWALL-002 | `firewall/*_mail.txt` | Port 25 rules |
| FIREWALL-003 | `firewall/*_mail.txt` | Ports 110, 143 closed/limited |
| FIREWALL-004 | `firewall/*_mail.txt` | Ports 993, 995, 465, 587 open |
| FIREWALL-005 | `firewall/*_mail.txt` | Port 4190 (ManageSieve) |
| FIREWALL-006 | `firewall/*_full.txt` | Rate limiting rules |
| FIREWALL-007 | `firewall/ip6tables_mail.txt` | IPv6 rules |
| FIREWALL-008 | `firewall/` | Consistency with services |

### MAC (SELinux/AppArmor)

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| MAC-001 | `mac/type.txt` | Active MAC type |
| MAC-002 | `mac/selinux_status.txt` | `Enforcing` |
| MAC-003 | `mac/apparmor_status.txt` | `enabled` |
| MAC-004 | `mac/apparmor_enforcement.txt` | Profiles in enforce mode |
| MAC-005 | `mac/selinux_booleans_mail.txt` | Mail booleans |
| MAC-006 | `mac/selinux_contexts.txt` | Confined processes |
| MAC-007 | `mac/selinux_avc_denials.txt` | No recent denials |
| MAC-008 | `mac/apparmor_violations.txt` | No recent violations |
| MAC-009 | `mac/selinux_ports.txt` | Labeled ports |

### Logging

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| LOGGING-001 | `postfix/config_active/postconf_n.txt` | Logging configured |
| LOGGING-002 | `dovecot/config_active/doveconf_n.txt` | `log_path` |
| LOGGING-003 | Config files | syslog facility |
| LOGGING-004 | `logs/critical_events_stats.txt` | Error count |
| LOGGING-005 | `logs/top_failed_auth_ips.txt` | Auth failure patterns |
| LOGGING-006 | `logs/` | Presence of rotated files |

### Storage

| Control ID | Evidence File | What to Look For |
|------------|---------------|------------------|
| STORAGE-001 | `system/partitions_mail.txt` | /var/mail separate |
| STORAGE-002 | `system/partitions_mail.txt` | /var/spool separate |
| STORAGE-003 | `system/partitions_mail.txt` | Available space > 20% |
| STORAGE-004 | `system/partitions_mail.txt` | Filesystem quotas |
| STORAGE-005 | `system/partitions_mail.txt` | Mount options |

## Verification Patterns

### Positive verification (value must be present)

```bash
grep -q "smtpd_helo_required = yes" postconf_n.txt && echo "PASS"
```

### Negative verification (value must be absent)

```bash
grep -q "0.0.0.0/0" postconf_n.txt && echo "FAIL: open relay"
```

### Range verification

```bash
value=$(grep message_size_limit postconf_n.txt | cut -d= -f2)
[ "$value" -gt 0 ] && [ "$value" -lt 52428800 ] && echo "PASS"
```

### Date comparison verification

```bash
expiry=$(openssl x509 -in cert.pem -noout -enddate | cut -d= -f2)
expiry_epoch=$(date -d "$expiry" +%s)
now_epoch=$(date +%s)
days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
[ "$days_left" -gt 30 ] && echo "PASS"
```

## Notes

- Paths are relative to the script output directory
- Some controls require correlation across multiple files
- Automatic verification covers ~65% of controls; the rest requires manual analysis or interviews
