# Rationale: Why MCSS is Needed

## The Gap in Security Standards

Mailservers are critical components of IT infrastructure, yet there are no structured security benchmarks for evaluating their configuration.

### Comparison with Other Technologies

| Technology | CIS Benchmark | STIG | Vendor Hardening Guide |
|------------|:-------------:|:----:|:----------------------:|
| Windows Server | ✓ | ✓ | ✓ |
| RHEL / Ubuntu | ✓ | ✓ | ✓ |
| Apache HTTP | ✓ | ✓ | ✓ |
| Nginx | ✓ | — | ✓ |
| PostgreSQL | ✓ | ✓ | ✓ |
| MySQL | ✓ | ✓ | ✓ |
| **Postfix** | — | — | Partial |
| **Dovecot** | — | — | Partial |
| **Exim** | — | — | Partial |
| **Cyrus** | — | — | Partial |

### Existing References

**NIST SP 800-45 v2** (Guidelines on Electronic Mail Security, 2007)
- General guidelines, not specific controls
- No scoring system
- Dated: references to Sendmail, POP3 without TLS, obsolete practices
- Not updated in 17+ years

**Vendor Documentation**
- Fragmented and incomplete
- Focus on features, not security
- No control prioritization

**Community Best Practices**
- Scattered across blogs, mailing lists, wikis
- Variable quality
- No systematic structure

## Practical Consequences

### For Mailserver Operators

- No reference for self-assessment
- Hardening based on "what you know"
- Difficulty justifying security investments

### For Auditors

- Subjective and non-comparable methodologies
- Difficulty communicating with management
- No objective remediation prioritization

### For Compliance

- Difficulty demonstrating compliance (GDPR, ISO 27001)
- Absence of controls mappable to regulatory frameworks
- Non-standardized audit reports

## The MCSS Approach

### Core Principle

Treat **misconfigurations as vulnerabilities** and apply the same rigorous methodology used to evaluate CVEs.

### Inspiration: CVSS

The [Common Vulnerability Scoring System](https://www.first.org/cvss/) is the de facto standard for assessing software vulnerability severity. MCSS adapts its principles:

| CVSS | MCSS |
|------|------|
| Software vulnerability | Misconfiguration |
| Exploit | Abuse scenario |
| Attack Vector | Exposure Vector |
| Impact (C/I/A) | Impact (C/I/A) |

### Key Differences

CVSS evaluates vulnerabilities **in code** — defects requiring vendor patches.

MCSS evaluates configurations **under operator control** — problems solvable without waiting for the vendor.

This changes some assumptions:
- "Remediation" is always possible (just reconfigure)
- The operator has complete agency
- The operational context is known

## Framework Objectives

### Primary

1. **Catalog** mailserver security controls systematically
2. **Quantify** the risk associated with each misconfiguration
3. **Prioritize** hardening efforts objectively
4. **Document** the methodology transparently and reproducibly

### Secondary

- Provide a basis for structured security audits
- Facilitate communication with non-technical stakeholders
- Enable comparisons across different environments
- Enable trend analysis over time

## Declared Limitations

MCSS **is not**:

- A ratified standard (ISO, NIST, CIS)
- An automated scanning tool
- A certification
- Complete — covers ~65% of controls; the rest requires interviews

MCSS **is**:

- An open and documented framework
- A methodological proposal to validate with the community
- A starting point for structured discussions
- A practical tool for those doing audits today

## Planned Evolution

The framework is under development. Areas of work:

- **Empirical validation** — collecting data on real configurations
- **Collaborative calibration** — feedback on control weighting
- **Coverage extension** — new controls, new components
- **Compliance mappings** — correlation with regulatory requirements

Community participation is essential to evolve from "one person's proposal" to "shared reference."
