# Metodologia MCSS

## Panoramica

MCSS (Mailserver Configuration Scoring System) assegna un punteggio numerico da 0.0 a 10.0 a ogni controllo di sicurezza, basandosi su due dimensioni:

1. **Exploitability** — Quanto è facile per un attaccante sfruttare la misconfiguration
2. **Impact** — Quali conseguenze produce lo sfruttamento

## Metriche Base

### Metriche di Exploitability

#### Exposure Vector (EV)

Descrive da dove un attaccante può sfruttare la misconfiguration.

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| Network | N | Sfruttabile da remoto via Internet | 0.0 |
| Adjacent | A | Richiede accesso alla rete locale | 0.1 |
| Local | L | Richiede accesso locale al sistema | 0.2 |
| Physical | P | Richiede accesso fisico | 0.3 |

**Esempi mailserver:**
- `N`: Open relay, TLS disabilitato su porta 25
- `A`: Servizio su porta non filtrata accessibile solo da LAN
- `L`: Permessi errati su file di configurazione
- `P`: Accesso console per boot in single user

#### Attack Complexity (AC)

Condizioni necessarie per lo sfruttamento che sono sotto controllo dell'attaccante.

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| Low | L | Sempre sfruttabile, nessuna condizione speciale | 0.0 |
| High | H | Richiede condizioni specifiche o conoscenza approfondita | 0.1 |

**Esempi:**
- `L`: Banner che rivela versione (sempre visibile)
- `H`: Race condition nel processing delle email

#### Attack Requirements (AR)

Condizioni necessarie che sono **fuori** dal controllo dell'attaccante.

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| None | N | Nessun prerequisito | 0.0 |
| Present | P | Richiede condizioni specifiche nell'ambiente target | 0.1 |

**Esempi:**
- `N`: Misconfiguration sempre sfruttabile
- `P`: Richiede che il target usi uno specifico backend di autenticazione

#### Privileges Required (PR)

Livello di privilegi necessari prima dello sfruttamento.

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| None | N | Nessuna autenticazione richiesta | 0.0 |
| Low | L | Credenziali utente base | 0.1 |
| High | H | Privilegi amministrativi | 0.2 |

**Esempi:**
- `N`: Attacco a servizio SMTP pubblico
- `L`: Richiede account email valido
- `H`: Richiede accesso root/admin

#### User Interaction (UI)

Azioni richieste da parte di un utente legittimo.

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| None | N | Completamente automatizzabile | 0.0 |
| Passive | P | Utente deve ricevere/aprire qualcosa | 0.1 |
| Active | A | Utente deve compiere azioni specifiche | 0.2 |

**Esempi:**
- `N`: Scanning automatico di porte
- `P`: Utente deve aprire email con allegato
- `A`: Utente deve cliccare link e inserire credenziali

### Metriche di Impact

Valutano le conseguenze sulla triade CIA (Confidentiality, Integrity, Availability).

#### Confidentiality Impact (VC)

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| None | N | Nessun impatto su confidenzialità | 0.2 |
| Low | L | Accesso a informazioni limitate | 0.1 |
| High | H | Accesso completo a dati sensibili | 0.0 |

**Esempi:**
- `N`: DoS senza data leak
- `L`: Enumerazione utenti via VRFY
- `H`: Lettura di tutte le email in transito

#### Integrity Impact (VI)

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| None | N | Nessun impatto su integrità | 0.2 |
| Low | L | Modifiche limitate possibili | 0.1 |
| High | H | Controllo completo sui dati | 0.0 |

**Esempi:**
- `N`: Information disclosure senza modifica
- `L`: Possibilità di aggiungere header a email
- `H`: Invio email falsificate a nome di chiunque

#### Availability Impact (VA)

| Valore | Codice | Descrizione | Peso |
|--------|--------|-------------|------|
| None | N | Nessun impatto su disponibilità | 0.2 |
| Low | L | Degrado parziale del servizio | 0.1 |
| High | H | Denial of Service completo | 0.0 |

**Esempi:**
- `N`: Data leak senza impatto su servizio
- `L`: Rallentamento per coda piena
- `H`: Blacklist IP, servizio inutilizzabile

### Metrica Supplementare

#### Remediation Complexity (RC)

Stima dell'effort per correggere la misconfiguration.

| Valore | Codice | Descrizione |
|--------|--------|-------------|
| Trivial | T | Modifica singolo parametro, nessun restart |
| Simple | S | Poche modifiche, restart servizio |
| Moderate | M | Modifiche multiple, test richiesti |
| Complex | C | Pianificazione necessaria, potenziale downtime |
| Architectural | A | Richiede redesign significativo |

**Nota:** RC non influenza il Base Score ma informa la pianificazione.

## Formula di Calcolo

### Exploitability Sub-Score

```
Exploitability = 1 - (EV + AC + AR + PR + UI) / 0.9
```

Dove 0.9 è la somma massima possibile dei pesi (0.3 + 0.1 + 0.1 + 0.2 + 0.2).

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

Il risultato è arrotondato a una cifra decimale.

## Severity Rating

| Range Score | Severity | Significato |
|-------------|----------|-------------|
| 0.0 | None | Controllo informativo |
| 0.1 — 3.9 | Low | Rischio limitato |
| 4.0 — 6.9 | Medium | Rischio moderato |
| 7.0 — 8.9 | High | Rischio elevato |
| 9.0 — 10.0 | Critical | Rischio critico |

## Vector String

Rappresentazione testuale compatta dei valori delle metriche:

```
MCSS:1.0/EV:N/AC:L/AR:N/PR:N/UI:N/VC:H/VI:H/VA:L/RC:S
```

Formato: `MCSS:<version>/<metric>:<value>/...`

## Esempi di Calcolo

### Esempio 1: Open Relay (POSTFIX-003)

**Scenario:** `mynetworks` include `0.0.0.0/0`, permettendo relay da qualsiasi IP.

| Metrica | Valore | Razionale |
|---------|--------|-----------|
| EV | N (0.0) | Sfruttabile da Internet |
| AC | L (0.0) | Nessuna condizione speciale |
| AR | N (0.0) | Sempre sfruttabile |
| PR | N (0.0) | Nessuna autenticazione |
| UI | N (0.0) | Automatizzabile |
| VC | N (0.2) | Non espone dati |
| VI | H (0.0) | Permette email falsificate |
| VA | H (0.0) | Causa blacklist |

```
Exploitability = 1 - (0.0 + 0.0 + 0.0 + 0.0 + 0.0) / 0.9 = 1.0
Impact = 1 - [(1-1) × (1-1) × (1-0)] = 1 - 0 = 1.0
Base Score = 10.0 × [1 - (1-1.0) × (1-1.0)] = 10.0
```

**Risultato:** 10.0 Critical

### Esempio 2: Banner Information Disclosure (POSTFIX-002)

**Scenario:** `smtpd_banner` rivela versione OS e Postfix.

| Metrica | Valore | Razionale |
|---------|--------|-----------|
| EV | N (0.0) | Visibile da rete |
| AC | H (0.1) | Richiede analisi per sfruttare |
| AR | P (0.1) | Utile solo se esistono CVE |
| PR | N (0.0) | Nessuna autenticazione |
| UI | N (0.0) | Automatizzabile |
| VC | L (0.1) | Rivela info limitate |
| VI | N (0.2) | Nessuna modifica |
| VA | N (0.2) | Nessun DoS |

```
Exploitability = 1 - (0.0 + 0.1 + 0.1 + 0.0 + 0.0) / 0.9 = 0.78
Impact = 1 - [(1-0.5) × (1-0) × (1-0)] = 1 - 0.5 = 0.5
Base Score = 10.0 × [1 - (1-0.78) × (1-0.5)] = 10.0 × [1 - 0.11] = 8.9
```

**Risultato:** 8.9 High

## Differenze da CVSS

| Aspetto | CVSS | MCSS |
|---------|------|------|
| Target | Vulnerabilità software | Misconfiguration |
| Remediation | Patch dal vendor | Riconfigurazione |
| Scope | Changed/Unchanged | Non applicato (sempre local) |
| Threat Metrics | Exploit Maturity | Non incluso in v1.0 |
| Environmental | CR/IR/AR modifier | Non incluso in v1.0 |

## Evoluzione Futura

Versioni successive potranno includere:

- **Threat Metrics** — Intelligence su sfruttamento attivo
- **Environmental Metrics** — Personalizzazione per contesto cliente
- **Subsequent Impact** — Impatto su sistemi collegati
