# MCSS Methodology

## Overview

MCSS (Mailserver Configuration Scoring System) assigns a numeric score from 0.0 to 10.0 to each security control, based on two dimensions:

1. **Exploitability** — How easy it is for an attacker to exploit the misconfiguration
2. **Impact** — What consequences result from exploitation

## Base Metrics

### Exploitability Metrics

#### Exposure Vector (EV)

Describes from where an attacker can exploit the misconfiguration.

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| Network | N | Exploitable remotely via Internet | 0.0 |
| Adjacent | A | Requires local network access | 0.1 |
| Local | L | Requires local system access | 0.2 |
| Physical | P | Requires physical access | 0.3 |

**Mailserver examples:**
- `N`: Open relay, TLS disabled on port 25
- `A`: Service on unfiltered port accessible only from LAN
- `L`: Incorrect permissions on configuration files
- `P`: Console access for single user boot

#### Attack Complexity (AC)

Conditions necessary for exploitation that are under the attacker's control.

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| Low | L | Always exploitable, no special conditions | 0.0 |
| High | H | Requires specific conditions or deep knowledge | 0.1 |

**Examples:**
- `L`: Banner revealing version (always visible)
- `H`: Race condition in email processing

#### Attack Requirements (AR)

Necessary conditions that are **outside** the attacker's control.

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| None | N | No prerequisites | 0.0 |
| Present | P | Requires specific conditions in target environment | 0.1 |

**Examples:**
- `N`: Misconfiguration always exploitable
- `P`: Requires target to use a specific authentication backend

#### Privileges Required (PR)

Level of privileges required before exploitation.

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| None | N | No authentication required | 0.0 |
| Low | L | Basic user credentials | 0.1 |
| High | H | Administrative privileges | 0.2 |

**Examples:**
- `N`: Attack on public SMTP service
- `L`: Requires valid email account
- `H`: Requires root/admin access

#### User Interaction (UI)

Actions required by a legitimate user.

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| None | N | Fully automatable | 0.0 |
| Passive | P | User must receive/open something | 0.1 |
| Active | A | User must perform specific actions | 0.2 |

**Examples:**
- `N`: Automated port scanning
- `P`: User must open email with attachment
- `A`: User must click link and enter credentials

### Impact Metrics

Evaluate consequences on the CIA triad (Confidentiality, Integrity, Availability).

#### Confidentiality Impact (VC)

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| None | N | No confidentiality impact | 0.2 |
| Low | L | Access to limited information | 0.1 |
| High | H | Complete access to sensitive data | 0.0 |

**Examples:**
- `N`: DoS without data leak
- `L`: User enumeration via VRFY
- `H`: Reading all emails in transit

#### Integrity Impact (VI)

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| None | N | No integrity impact | 0.2 |
| Low | L | Limited modifications possible | 0.1 |
| High | H | Complete control over data | 0.0 |

**Examples:**
- `N`: Information disclosure without modification
- `L`: Ability to add headers to emails
- `H`: Sending spoofed emails on behalf of anyone

#### Availability Impact (VA)

| Value | Code | Description | Weight |
|-------|------|-------------|--------|
| None | N | No availability impact | 0.2 |
| Low | L | Partial service degradation | 0.1 |
| High | H | Complete Denial of Service | 0.0 |

**Examples:**
- `N`: Data leak without service impact
- `L`: Slowdown due to full queue
- `H`: IP blacklist, service unusable

### Supplemental Metric

#### Remediation Complexity (RC)

Estimates effort required to fix the misconfiguration.

| Value | Code | Description |
|-------|------|-------------|
| Trivial | T | Single parameter change, no restart |
| Simple | S | Few changes, service restart |
| Moderate | M | Multiple changes, testing required |
| Complex | C | Planning needed, potential downtime |
| Architectural | A | Requires significant redesign |

**Note:** RC does not affect Base Score but informs planning.

## Calculation Formula

### Exploitability Sub-Score

```
Exploitability = 1 - (EV + AC + AR + PR + UI) / 0.9
```

Where 0.9 is the maximum possible sum of weights (0.3 + 0.1 + 0.1 + 0.2 + 0.2).

### Impact Sub-Score

```
VC_impact = 1 - (VC_weight / 0.2)
VI_impact = 1 - (VI_weight / 0.2)
VA_impact = 1 - (VA_weight / 0.2)

Impact = 1 - [(1 - VC_impact) × (1 - VI_impact) × (1 - VA_impact)]
```

### Base Score

```
Base Score = 10.0 × [1 - (1 - Exploitability) × (1 - Impact)]
```

The result is rounded to one decimal place.

## Severity Rating

| Score Range | Severity | Meaning |
|-------------|----------|---------|
| 0.0 | None | Informational control |
| 0.1 — 3.9 | Low | Limited risk |
| 4.0 — 6.9 | Medium | Moderate risk |
| 7.0 — 8.9 | High | Elevated risk |
| 9.0 — 10.0 | Critical | Critical risk |

## Vector String

Compact textual representation of metric values:

```
MCSS:1.0/EV:N/AC:L/AR:N/PR:N/UI:N/VC:H/VI:H/VA:L/RC:S
```

Format: `MCSS:<version>/<metric>:<value>/...`

## Calculation Examples

### Example 1: Open Relay (POSTFIX-003)

**Scenario:** `mynetworks` includes `0.0.0.0/0`, allowing relay from any IP.

| Metric | Value | Rationale |
|--------|-------|-----------|
| EV | N (0.0) | Exploitable from Internet |
| AC | L (0.0) | No special conditions |
| AR | N (0.0) | Always exploitable |
| PR | N (0.0) | No authentication |
| UI | N (0.0) | Automatable |
| VC | N (0.2) | No data exposure |
| VI | H (0.0) | Allows spoofed emails |
| VA | H (0.0) | Causes blacklisting |

```
Exploitability = 1 - (0.0 + 0.0 + 0.0 + 0.0 + 0.0) / 0.9 = 1.0
Impact = 1 - [(1-1) × (1-1) × (1-0)] = 1 - 0 = 1.0
Base Score = 10.0 × [1 - (1-1.0) × (1-1.0)] = 10.0
```

**Result:** 10.0 Critical

### Example 2: Banner Information Disclosure (POSTFIX-002)

**Scenario:** `smtpd_banner` reveals OS and Postfix version.

| Metric | Value | Rationale |
|--------|-------|-----------|
| EV | N (0.0) | Visible from network |
| AC | H (0.1) | Requires analysis to exploit |
| AR | P (0.1) | Useful only if CVEs exist |
| PR | N (0.0) | No authentication |
| UI | N (0.0) | Automatable |
| VC | L (0.1) | Reveals limited info |
| VI | N (0.2) | No modification |
| VA | N (0.2) | No DoS |

```
Exploitability = 1 - (0.0 + 0.1 + 0.1 + 0.0 + 0.0) / 0.9 = 0.78
Impact = 1 - [(1-0.5) × (1-0) × (1-0)] = 1 - 0.5 = 0.5
Base Score = 10.0 × [1 - (1-0.78) × (1-0.5)] = 10.0 × [1 - 0.11] = 8.9
```

**Result:** 8.9 High

## Differences from CVSS

| Aspect | CVSS | MCSS |
|--------|------|------|
| Target | Software vulnerabilities | Misconfigurations |
| Remediation | Vendor patch | Reconfiguration |
| Scope | Changed/Unchanged | Not applied (always local) |
| Threat Metrics | Exploit Maturity | Not included in v1.0 |
| Environmental | CR/IR/AR modifier | Not included in v1.0 |

## Future Evolution

Future versions may include:

- **Threat Metrics** — Intelligence on active exploitation
- **Environmental Metrics** — Customization for client context
- **Subsequent Impact** — Impact on connected systems
