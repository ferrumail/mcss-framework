# Contributing to MCSS

Thank you for your interest in contributing! MCSS is a young project and every contribution matters.

## How to Contribute

### Reporting Issues

Open an issue for:
- Bugs in tools or scripts
- Errors in controls (wrong IDs, incorrect evidence files)
- Unclear documentation
- Requests for new controls

### Proposing Changes

1. Fork the repository
2. Create a branch (`git checkout -b feature/new-control`)
3. Commit your changes (`git commit -am 'Add control XYZ'`)
4. Push the branch (`git push origin feature/new-control`)
5. Open a Pull Request

## Areas Where Help is Needed

### Score Calibration (High Priority)

MCSS scores are based on practical experience, but more perspectives are valuable:

- Are some controls over/underestimated?
- Do Exploitability metrics reflect real-world scenarios?
- Is Impact calibrated correctly?

When proposing score changes, include:
- Control ID
- Current vs. proposed values
- Rationale (attack scenario, practical experience, references)

### Missing Controls

What checks do you perform in your audits that aren't covered? We need:

- Control description
- How to verify it (evidence file, command)
- Proposed MCSS scoring
- Suggested severity

### Testing on Different Environments

The collection script is primarily tested on:
- Debian/Ubuntu with Postfix + Dovecot
- RHEL/CentOS with Postfix + Dovecot

Testing needed on:
- FreeBSD
- Exim as primary MTA
- Cyrus as MDA
- Containerized setups
- Cloud relays (AWS SES, etc.)

### Translations

MCSS uses YAML files for localization. To add a new language:

1. Copy `l10n/en.yaml` to `l10n/XX.yaml` (where XX is the language code)
2. Translate `name` and `description` fields for each control
3. Run `tools/build_localized_controls.pl --lang XX`
4. Create `XX/` directory with translated docs

Currently available: English, Italian

### Documentation

- Usage examples
- Tutorials for specific scenarios
- Improved explanations

## File Formats

### Master CSV (controls/mcss_controls_master.csv)

Language-neutral technical data:

```csv
control_id,area,component,evidence_file,severity,EV,AC,AR,PR,UI,VC,VI,VA,RC
POSTFIX-001,MTA,Postfix,postfix/version.txt,High,N,H,P,N,N,L,N,N,S
```

**Do not add translatable text here.** Names and descriptions go in YAML files.

### Localization YAML (l10n/*.yaml)

```yaml
controls:
  POSTFIX-001:
    name: Postfix version supported
    description: Verify that Postfix version is still maintained
```

### Field Reference

| Field | Type | Valid Values |
|-------|------|--------------|
| control_id | string | `AREA-NNN` (e.g., POSTFIX-001) |
| area | string | MTA, MDA, TLS, Auth, etc. |
| component | string | Specific component name |
| evidence_file | string | Relative path in collection output |
| severity | string | Critical, High, Medium, Low, Info |
| EV | char | N, A, L, P |
| AC | char | L, H |
| AR | char | N, P |
| PR | char | N, L, H |
| UI | char | N, P, A |
| VC | char | N, L, H |
| VI | char | N, L, H |
| VA | char | N, L, H |
| RC | char | T, S, M, C, A |

### Validation

Before submitting, validate your changes:

```bash
# Validate master CSV structure
perl tools/validate_mcss_csv.pl controls/mcss_controls_master.csv

# Build and validate localized output
perl tools/build_localized_controls.pl --lang en
perl tools/validate_mcss_csv.pl -s en/controls/*.csv
```

## Code Style

### Perl

- `use strict; use warnings;`
- Indentation: 4 spaces
- Comments in English
- POD documentation for public functions

### YAML

- 2 spaces indentation
- UTF-8 encoding
- No trailing whitespace

### Shell

- POSIX-compatible where possible
- Avoid bashisms unless necessary
- Comments for complex sections

## Commit Messages

Suggested format:

```
[area] Brief description

Longer description if needed.

Fixes #123
```

Areas: `controls`, `tools`, `docs`, `schema`, `l10n`, `examples`

Examples:
- `[controls] Add POSTFIX-019 for smtp_tls_mandatory_protocols`
- `[l10n] Add German translation`
- `[tools] Fix score calculation for edge case`
- `[docs] Improve METHODOLOGY.md examples`

## Pull Request Guidelines

- One logical change per PR
- Include tests/validation output if applicable
- Update relevant documentation
- Reference related issues

## Code of Conduct

- Mutual respect
- Constructive feedback
- Focus on technical merit
- Welcoming to new contributors

## Questions?

Open an issue with the `question` label.

## License

By contributing, you agree that your contributions will be licensed under the Artistic License 2.0.
