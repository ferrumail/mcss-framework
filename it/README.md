# MCSS — Mailserver Configuration Scoring System

Un framework aperto per la valutazione della sicurezza dei mailserver.

## Il problema

Esistono CIS Benchmark per Linux, Apache, MySQL, PostgreSQL, Windows Server — ma **non per i mailserver**. Chi gestisce Postfix, Dovecot, Exim o Cyrus in produzione non ha un riferimento strutturato per:

- Valutare la configurazione di sicurezza
- Prioritizzare gli interventi di hardening
- Dimostrare compliance a requisiti normativi
- Confrontare ambienti diversi con criteri oggettivi

NIST SP 800-45 v2 (2007) fornisce linee guida generali ma non controlli specifici con scoring. È anche datato — parla ancora di Sendmail come scelta primaria.


## La proposta

MCSS adatta il modello [CVSS](https://www.first.org/cvss/) (Common Vulnerability Scoring System) al contesto delle configurazioni mailserver:

- **169 controlli** organizzati per componente
- **Scoring 0.0-10.0** basato su exploitability e impact
- **Metodologia documentata** e riproducibile
- **Correlazione con evidenze** raccolte automaticamente


## Lo scopo

MCSS è sviluppato sia come strumento pratico per la valutazione della qualità infrastrutturale, sia come iniziativa di ricerca tecnica a lungo termine.
I servizi operativi come Fast Scan e le attività di assessment contribuiscono a sostenere lo sviluppo e la validazione del framework.
L'obiettivo di MCSS non è aggiungere complessità alle pratiche di verifica, ma aiutare i team tecnici a concentrarsi su miglioramenti operativi concreti e significativi.

## Filosofia / Principi

- misurabilità
- ripetibilità
- indipendenza dal fornitore

## Documenti di approfondimento

Per comprendere meglio l'impostazione metodologica del framework:

- [La visione](docs/VISIONE.md)
- [Perché MCSS](docs/Perché_MCSS.md)



## Quick Start

### 1. Raccogli i dati

Usa [mailserver-audit-collect](https://github.com/TUOUSER/mailserver-audit-collect) sul server da analizzare:

```bash
sudo ./mailserver-audit-collect.sh
# Produce: mailaudit_hostname_timestamp.tar.gz
```

### 2. Valida i controlli

```bash
cd mcss-framework/tools
perl validate_mcss_csv.pl -s ../controls/*.csv
```

### 3. Importa in PostgreSQL (opzionale)

```bash
createdb mcss_audit
perl import_mcss_controls.pl -c -d mcss_audit ../controls/*.csv
```

### 4. Analizza

Correla manualmente le evidenze raccolte con i controlli, oppure sviluppa i tuoi script di analisi.

## Struttura repository

```
mcss-framework/
├── docs/
│   ├── RATIONALE.md        # Perché serve questo framework
│   ├── METHODOLOGY.md      # Come funziona lo scoring
│   └── EVIDENCE_MAPPING.md # Quali file → quali controlli
│
├── controls/               # Definizione controlli con scoring MCSS
│   ├── mcss_mta_postfix.csv
│   ├── mcss_mta_exim.csv
│   ├── mcss_mda_dovecot.csv
│   ├── mcss_mda_cyrus.csv
│   └── ... (20 file totali)
│
├── tools/
│   ├── validate_mcss_csv.pl      # Validazione e calcolo score
│   └── import_mcss_controls.pl   # Import in PostgreSQL
│
├── schema/
│   └── mcss_postgresql.sql       # Schema database
│
└── examples/
    └── sample_output/            # Output di esempio
```

## Copertura controlli

| Area | Controlli | Componenti |
|------|-----------|------------|
| MTA | 36 | Postfix, Exim |
| MDA | 30 | Dovecot, Cyrus |
| TLS/Certificati | 12 | Validità, cipher, protocolli |
| Autenticazione | 10 | SASL, backend, policy |
| Email Auth | 15 | DKIM, DMARC, SPF |
| Antispam/Antivirus | 15 | SpamAssassin, Rspamd, ClamAV |
| Protezione | 24 | Firewall, SELinux/AppArmor, Fail2ban |
| Operazioni | 27 | Logging, storage, patching, alias |

## Metriche MCSS

Ogni controllo è valutato su due dimensioni:

**Exploitability** — Quanto è facile sfruttare la misconfiguration
- Exposure Vector (N/A/L/P)
- Attack Complexity (L/H)
- Attack Requirements (N/P)
- Privileges Required (N/L/H)
- User Interaction (N/P/A)

**Impact** — Conseguenze sulla triade CIA
- Confidentiality Impact (N/L/H)
- Integrity Impact (N/L/H)
- Availability Impact (N/L/H)

### Metodologia e criteri di scoring

Il modello MCSS si basa su criteri espliciti di valutazione delle configurazioni. Sebbene la scelta di pesi e classificazioni rifletta esperienze tecniche e giudizi umani, questi criteri sono:

 * **espliciti e documentati**, per garantire trasparenza;
 * **replicabili**, affinché valutazioni diverse diano risultati confrontabili;
 * **coerenti nel tempo**, con la possibilità di revisioni migliorative attraverso feedback della comunità.

L’uso di scelte metodologiche non elimina la soggettività, ma la **struttura e la documentazione consentono una tensione continua verso miglioramenti**. Le calibrazioni future potranno anche essere validate empiricamente.

Per un approfondimento sulle scelte metodologiche e sulla filosofia del modello, vedi anche i documenti aggiuntivi (`docs/VISIONE.md`, `docs/Perché_MCSS.md`, [METHODOLOGY.md](docs/METHODOLOGY.md)).

## Contribuire

Il framework è in sviluppo attivo. Servono:

- **Feedback sulla calibrazione** — Gli score assegnati hanno senso?
- **Controlli mancanti** — Cosa manca?
- **Test su ambienti diversi** — Funziona su Debian? FreeBSD? Container?
- **Documentazione** — Esempi, traduzioni, tutorial

Vedi [CONTRIBUTING.md](CONTRIBUTING.md).

Governance (Initial Proposal)

    MCSS mira ad evolversi as uno standard aperto
    Le decisioni saranno prese in trasparenza nelle Discussions su Github
    Chi contribuisce dimostrando competenza sarà un candidato a mantainers
    La governance evolverà con la dimensione della comunità di contributori, 
    se attualmente la leadership è detenuta dal fondatore, questa non è una 
    condizione immutabile. 
    

## Limitazioni note

- Copre solo il 65% dei controlli di un audit completo (il resto richiede interviste)
- La calibrazione degli score è basata su esperienza, non su dati statistici
- Focus su stack open source (Postfix/Exim + Dovecot/Cyrus)
- Non copre Exchange, Zimbra, soluzioni cloud

## Licenza

Artistic 2.0 — vedi [LICENSE](LICENSE).

## Riferimenti

- [CVSS v4.0 Specification](https://www.first.org/cvss/v4.0/)
- [NIST SP 800-45 v2](https://csrc.nist.gov/publications/detail/sp/800-45/version-2/final)
- [CIS Controls v8](https://www.cisecurity.org/controls)
- [RFC 5321 — SMTP](https://datatracker.ietf.org/doc/html/rfc5321)
- [RFC 2142 — Mailbox Names](https://datatracker.ietf.org/doc/html/rfc2142)
