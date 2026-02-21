# MCSS — Mailserver Configuration Scoring System

An open framework for assessing mailserver security configurations.

## The Problem

CIS Benchmarks exist for Linux, Apache, MySQL, PostgreSQL, Windows Server — but **not for mailservers**. Administrators running Postfix, Dovecot, Exim, or Cyrus in production lack a structured reference for:

- Evaluating security configurations
- Prioritizing hardening efforts
- Demonstrating compliance
- Comparing environments with objective criteria

NIST SP 800-45 v2 (2007) provides general guidelines but no specific controls with scoring — and it's nearly two decades old.

## The Solution

MCSS adapts the [CVSS](https://www.first.org/cvss/) (Common Vulnerability Scoring System) model to mailserver configurations:

- **169 controls** organized by component
- **Scoring 0.0–10.0** based on exploitability and impact
- **Documented methodology**, transparent and reproducible
- **Evidence correlation** with automated data collection

## Purpose

MCSS is developed both as a practical tool for infrastructure quality assessment and as a long-term technical research initiative.

Operational services such as Fast Scan and assessment activities help sustain the development and validation of the framework.

The goal of MCSS is not to add complexity to verification practices, but to help technical teams focus on meaningful operational improvements.

## Quick Start

### 1. Collect Data

Use [mailserver-audit-collect](https://github.com/ferrumail/mailserver-audit-collect) on the target server:

```bash
sudo ./mailserver-audit-collect.sh
# Output: mailaudit_hostname_timestamp.tar.gz
```

### 2. Validate Controls

```bash
cd mcss-framework/tools
perl validate_mcss_csv.pl -s ../en/controls/*.csv
```

### 3. Import to PostgreSQL (optional)

```bash
createdb mcss_audit
perl import_mcss_controls.pl -c -d mcss_audit ../en/controls/*.csv
```

### 4. Analyze

Correlate collected evidence with controls manually, or develop your own analysis scripts.

## Repository Structure

```
mcss-framework/
├── controls/
│   └── mcss_controls_master.csv   # Technical data (language-neutral)
│
├── l10n/
│   ├── en.yaml                    # English translations
│   └── it.yaml                    # Italian translations
│
├── tools/
│   ├── validate_mcss_csv.pl       # Validation and scoring
│   ├── import_mcss_controls.pl    # PostgreSQL import
│   └── build_localized_controls.pl # Generate localized CSVs
│
├── schema/
│   └── mcss_postgresql.sql        # Database schema
│
├── en/                            # English documentation & controls
│   ├── README.md
│   ├── CONTRIBUTING.md
│   ├── controls/                  # Generated localized CSVs
│   ├── docs/
│   └── examples/
│
└── it/                            # Italian documentation & controls
    └── ...
```

## Control Coverage

| Area | Controls | Components |
|------|----------|------------|
| MTA | 36 | Postfix, Exim |
| MDA | 30 | Dovecot, Cyrus |
| TLS/Certificates | 12 | Validity, ciphers, protocols |
| Authentication | 10 | SASL, backends, policy |
| Email Auth | 15 | DKIM, DMARC, SPF |
| Antispam/Antivirus | 15 | SpamAssassin, Rspamd, ClamAV |
| Protection | 24 | Firewall, SELinux/AppArmor, Fail2ban |
| Operations | 27 | Logging, storage, patching, aliases |

## MCSS Metrics

Each control is evaluated on two dimensions:

**Exploitability** — How easily can the misconfiguration be exploited?
- Exposure Vector (N/A/L/P)
- Attack Complexity (L/H)
- Attack Requirements (N/P)
- Privileges Required (N/L/H)
- User Interaction (N/P/A)

**Impact** — What are the consequences on the CIA triad?
- Confidentiality Impact (N/L/H)
- Integrity Impact (N/L/H)
- Availability Impact (N/L/H)

See [Methodology](en/docs/METHODOLOGY.md) for details.

## Localization

MCSS separates technical data from translatable text:

- `controls/mcss_controls_master.csv` — metrics and evidence files (language-neutral)
- `l10n/*.yaml` — control names and descriptions per language
- `tools/build_localized_controls.pl` — generates localized CSVs

Currently available: **English**, **Italian**

Contributions for other languages welcome!

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Key areas where help is needed:
- Score calibration feedback
- Missing controls identification
- Testing on diverse environments
- Translations

## Governance (Initial Proposal)

- MCSS aims to evolve as an open standard
- Decisions are made transparently via GitHub Discussions
- Contributors who demonstrate sustained expertise may become maintainers
- Governance will evolve as the contributor base grows

MCSS is currently founder-led but intended to evolve into a community-driven standard.

Maintainers will emerge based on sustained, high-quality contributions.

## Known Limitations

- Covers ~65% of a complete audit (the rest requires interviews)
- Score calibration is experience-based, not statistically validated
- Focus on open source stack (Postfix/Exim + Dovecot/Cyrus)
- Does not cover Exchange, Zimbra, or cloud solutions

## License

Artistic License 2.0 — see [LICENSE](LICENSE).

## References

- [CVSS v4.0 Specification](https://www.first.org/cvss/v4.0/)
- [NIST SP 800-45 v2](https://csrc.nist.gov/publications/detail/sp/800-45/version-2/final)
- [CIS Controls v8](https://www.cisecurity.org/controls)
- [RFC 5321 — SMTP](https://datatracker.ietf.org/doc/html/rfc5321)
- [RFC 2142 — Mailbox Names](https://datatracker.ietf.org/doc/html/rfc2142)
