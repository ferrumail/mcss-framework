# Example Output: Controls Validation

Command output:
```
perl tools/validate_mcss_csv.pl -s controls/*.csv
```

## Result

```
=== MCSS CSV Validator ===

Processing: controls/mcss_mta_postfix.csv
  [OK] 18 controls validated

Processing: controls/mcss_mta_exim.csv
  [OK] 18 controls validated

Processing: controls/mcss_mda_dovecot.csv
  [OK] 16 controls validated

Processing: controls/mcss_mda_cyrus.csv
  [OK] 14 controls validated

Processing: controls/mcss_tls.csv
  [OK] 12 controls validated

Processing: controls/mcss_auth.csv
  [OK] 10 controls validated

Processing: controls/mcss_dkim.csv
  [OK] 6 controls validated

Processing: controls/mcss_dmarc.csv
  [OK] 5 controls validated

Processing: controls/mcss_spf.csv
  [OK] 4 controls validated

Processing: controls/mcss_antispam.csv
  [OK] 8 controls validated

Processing: controls/mcss_antivirus.csv
  [OK] 7 controls validated

Processing: controls/mcss_firewall.csv
  [OK] 8 controls validated

Processing: controls/mcss_mac.csv
  [OK] 9 controls validated

Processing: controls/mcss_fail2ban.csv
  [OK] 7 controls validated

Processing: controls/mcss_policy.csv
  [OK] 6 controls validated

Processing: controls/mcss_logging.csv
  [OK] 6 controls validated

Processing: controls/mcss_storage.csv
  [OK] 5 controls validated

Processing: controls/mcss_rfc2142.csv
  [OK] 4 controls validated

Processing: controls/mcss_timestamp.csv
  [OK] 3 controls validated

Processing: controls/mcss_patching.csv
  [OK] 3 controls validated

=== Score Statistics ===

Total controls: 169

By Severity:
  Critical:  28 (16.6%)
  High:      67 (39.6%)
  Medium:    56 (33.1%)
  Low:       11 (6.5%)
  Info:       7 (4.1%)

Score Distribution:
  9.0-10.0 (Critical): 28
  7.0-8.9  (High):     52
  4.0-6.9  (Medium):   71
  0.1-3.9  (Low):      11
  0.0      (Info):      7

Average Score: 6.8
Max Score: 10.0
Min Score: 0.0

Top 10 Critical Controls:
  POSTFIX-003   mynetworks_restrictive          10.0
  POSTFIX-004   relay_restrictions              10.0
  EXIM-004      acl_smtp_rcpt_defined           10.0
  EXIM-006      no_open_relay                   10.0
  DOVECOT-002   ssl_required                    10.0
  DOVECOT-006   disable_plaintext_auth          10.0
  AUTH-005      auth_only_over_tls              10.0
  AUTH-008      no_plain_without_tls            10.0
  TLS-001       cert_valid                      10.0
  ANTIVIRUS-001 clamav_installed                10.0
```

## Notes

- Flag `-s` enables statistics
- Without flag, shows structural validation only
- Exit code 0 = all files valid
- Exit code 1 = errors found
