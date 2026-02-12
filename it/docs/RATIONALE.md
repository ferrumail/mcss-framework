# Rationale: Perché serve MCSS

## Il gap negli standard di sicurezza

I mailserver sono componenti critici dell'infrastruttura IT, ma non esistono benchmark di sicurezza strutturati per valutarne la configurazione.

### Confronto con altre tecnologie

| Tecnologia | CIS Benchmark | STIG | Vendor Hardening Guide |
|------------|:-------------:|:----:|:----------------------:|
| Windows Server | ✓ | ✓ | ✓ |
| RHEL / Ubuntu | ✓ | ✓ | ✓ |
| Apache HTTP | ✓ | ✓ | ✓ |
| Nginx | ✓ | — | ✓ |
| PostgreSQL | ✓ | ✓ | ✓ |
| MySQL | ✓ | ✓ | ✓ |
| **Postfix** | — | — | Parziale |
| **Dovecot** | — | — | Parziale |
| **Exim** | — | — | Parziale |
| **Cyrus** | — | — | Parziale |

### Riferimenti esistenti

**NIST SP 800-45 v2** (Guidelines on Electronic Mail Security, 2007)
- Linee guida generali, non controlli specifici
- Nessun sistema di scoring
- Datato: riferimenti a Sendmail, POP3 senza TLS, pratiche obsolete
- Non aggiornato da 17+ anni

**Documentazione vendor**
- Frammentata e incompleta
- Focus su funzionalità, non su sicurezza
- Nessuna prioritizzazione dei controlli

**Best practice della community**
- Sparse in blog, mailing list, wiki
- Qualità variabile
- Nessuna struttura sistematica

## Conseguenze pratiche

### Per chi gestisce mailserver

- Nessun riferimento per self-assessment
- Hardening basato su "quello che si sa"
- Difficoltà a giustificare investimenti in sicurezza

### Per chi fa audit

- Metodologie soggettive e non confrontabili
- Difficoltà a comunicare con il management
- Nessuna prioritizzazione oggettiva delle remediation

### Per compliance

- Difficoltà a dimostrare conformità (GDPR, ISO 27001)
- Assenza di controlli mappabili su framework normativi
- Audit report non standardizzati

## L'approccio MCSS

### Principio base

Trattare le **misconfigurazioni come vulnerabilità** e applicare la stessa metodologia rigorosa usata per valutare i CVE.

### Ispirazione: CVSS

Il [Common Vulnerability Scoring System](https://www.first.org/cvss/) è lo standard de facto per valutare la severità delle vulnerabilità software. MCSS ne adatta i principi:

| CVSS | MCSS |
|------|------|
| Vulnerabilità software | Misconfiguration |
| Exploit | Scenario di abuso |
| Attack Vector | Exposure Vector |
| Impact (C/I/A) | Impact (C/I/A) |

### Differenze chiave

CVSS valuta vulnerabilità **nel codice** — difetti che richiedono patch dal vendor.

MCSS valuta configurazioni **sotto controllo dell'operatore** — problemi risolvibili senza attendere il vendor.

Questo cambia alcune assunzioni:
- La "remediation" è sempre possibile (basta riconfigurare)
- L'operatore ha agency completa
- Il contesto operativo è noto

## Obiettivi del framework

### Primari

1. **Catalogare** i controlli di sicurezza per mailserver in modo sistematico
2. **Quantificare** il rischio associato a ogni misconfiguration
3. **Prioritizzare** gli interventi di hardening in modo oggettivo
4. **Documentare** la metodologia in modo trasparente e riproducibile

### Secondari

- Fornire una base per audit di sicurezza strutturati
- Facilitare la comunicazione con stakeholder non tecnici
- Permettere confronti tra ambienti diversi
- Abilitare trend analysis nel tempo

## Limiti dichiarati

MCSS **non è**:

- Uno standard ratificato (ISO, NIST, CIS)
- Un tool di scanning automatico
- Una certificazione
- Completo — copre ~65% dei controlli; il resto richiede interviste

MCSS **è**:

- Un framework aperto e documentato
- Una proposta metodologica da validare con la community
- Un punto di partenza per discussioni strutturate
- Uno strumento pratico per chi fa audit oggi

## Evoluzione prevista

Il framework è in sviluppo. Aree di lavoro:

- **Validazione empirica** — raccolta dati su configurazioni reali
- **Calibrazione collaborativa** — feedback sulla pesatura dei controlli
- **Estensione copertura** — nuovi controlli, nuovi componenti
- **Mappature compliance** — correlazione con requisiti normativi

La partecipazione della community è essenziale per evolvere da "proposta di un singolo" a "riferimento condiviso".
