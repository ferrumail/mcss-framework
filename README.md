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

## ⚖️ Governance: Holacracy & Self-Management
I released this methodology under the Artistic License 2.0 to ensure it remains free, accessible, and consistent. To evolve it, I am proposing an Holacracy model instead of a traditional steering group.
Why Holacracy?

    Purpose-Driven: No bosses, just a shared mission. We are led by the project’s goals, not by a hierarchy.
    Distributed Authority: If you fill a role, you have full decision-making power within its scope—no bureaucratic bottlenecks.
    Roles over Titles: Our structure is made of dynamic circles and roles that evolve alongside the project.

    "In this system, authority belongs to the process and the roles that serve the purpose, not to individuals."

### 🚀 Join the Circle
To kickstart this process, I have defined the following Key Roles. If you have the expertise and want to help shape a new security standard for mail servers, this is your chance to lead a specific domain:

    Methodology Architect: Ensures the integrity and consistency of the master check registry.
    Implementation Leads (Postfix, Exim, Dovecot, etc.): Technical owners of software-specific configurations and YAML files.
    Linguistic Steward: Manages I18N YAML files and ensures high-quality technical translations.
    Security Auditor: Monitors new vulnerabilities and updates the standard's security policies.

*Ready to step into one of these roles? Open an Issue or start a thread in the Discussions section!*


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
