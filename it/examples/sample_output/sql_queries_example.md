# Esempio: Query SQL per Analisi

Dopo aver importato i controlli con `import_mcss_controls.pl`, puoi usare queste query.

## Query di Base

### Controlli critici

```sql
SELECT control_id, control_name, base_score, vector_string
FROM mcss_controls
WHERE severity = 'Critical'
ORDER BY base_score DESC;
```

### Riepilogo per area

```sql
SELECT * FROM mcss_summary_by_area;
```

Output:
```
   area    | total | critical | high | medium | low | avg_score | max_score
-----------+-------+----------+------+--------+-----+-----------+-----------
 MTA       |    36 |        6 |   18 |     10 |   2 |       7.2 |      10.0
 MDA       |    30 |        4 |   14 |     10 |   2 |       6.9 |      10.0
 Auth      |    10 |        2 |    5 |      3 |   0 |       7.1 |      10.0
 TLS       |    12 |        3 |    6 |      3 |   0 |       7.4 |      10.0
 ...
```

### Distribuzione severity

```sql
SELECT * FROM mcss_severity_distribution;
```

Output:
```
 severity | count | percentage | avg_score
----------+-------+------------+-----------
 Critical |    28 |       16.6 |       9.8
 High     |    67 |       39.6 |       7.6
 Medium   |    56 |       33.1 |       5.4
 Low      |    11 |        6.5 |       2.8
 Info     |     7 |        4.1 |       0.0
```

## Query Avanzate

### Controlli per complessità di remediation

```sql
SELECT 
    rc,
    CASE rc
        WHEN 'T' THEN 'Trivial'
        WHEN 'S' THEN 'Simple'
        WHEN 'M' THEN 'Moderate'
        WHEN 'C' THEN 'Complex'
        WHEN 'A' THEN 'Architectural'
    END as remediation_complexity,
    COUNT(*) as count,
    ROUND(AVG(base_score), 1) as avg_score
FROM mcss_controls
GROUP BY rc
ORDER BY 
    CASE rc WHEN 'T' THEN 1 WHEN 'S' THEN 2 WHEN 'M' THEN 3 WHEN 'C' THEN 4 WHEN 'A' THEN 5 END;
```

### Quick wins: alto impatto, facile remediation

```sql
SELECT 
    control_id,
    control_name,
    base_score,
    CASE rc
        WHEN 'T' THEN 'Trivial'
        WHEN 'S' THEN 'Simple'
    END as remediation
FROM mcss_controls
WHERE base_score >= 7.0 
  AND rc IN ('T', 'S')
ORDER BY base_score DESC;
```

### Controlli che richiedono Network access (attaccabili da remoto)

```sql
SELECT control_id, control_name, base_score, severity
FROM mcss_controls
WHERE ev = 'N'  -- Exposure Vector = Network
  AND base_score >= 7.0
ORDER BY base_score DESC;
```

### Controlli con impatto su confidenzialità

```sql
SELECT control_id, control_name, base_score
FROM mcss_controls
WHERE vc = 'H'  -- Confidentiality Impact = High
ORDER BY base_score DESC;
```

## Uso con Risultati Audit

### Inserire risultato audit

```sql
INSERT INTO mcss_audit_results 
    (audit_id, hostname, control_id, status, finding, evidence)
VALUES 
    ('AUDIT-2025-001', 'mail.example.com', 'POSTFIX-003', 'Fail', 
     'mynetworks include subnet troppo ampia', 
     'mynetworks = 10.0.0.0/8');
```

### Report audit: controlli falliti

```sql
SELECT 
    r.control_id,
    c.control_name,
    c.base_score,
    c.severity,
    r.finding
FROM mcss_audit_results r
JOIN mcss_controls c ON r.control_id = c.control_id
WHERE r.audit_id = 'AUDIT-2025-001'
  AND r.status = 'Fail'
ORDER BY c.base_score DESC;
```

### Punteggio complessivo audit

```sql
WITH audit_stats AS (
    SELECT 
        COUNT(*) FILTER (WHERE status = 'Pass') as passed,
        COUNT(*) FILTER (WHERE status = 'Fail') as failed,
        COUNT(*) FILTER (WHERE status = 'N/A') as na,
        COUNT(*) as total
    FROM mcss_audit_results
    WHERE audit_id = 'AUDIT-2025-001'
)
SELECT 
    passed,
    failed,
    na,
    total,
    ROUND(100.0 * passed / NULLIF(passed + failed, 0), 1) as compliance_pct
FROM audit_stats;
```

### Risk score pesato

```sql
SELECT 
    ROUND(
        SUM(CASE WHEN r.status = 'Fail' THEN c.base_score ELSE 0 END) /
        NULLIF(SUM(c.base_score), 0) * 100
    , 1) as risk_exposure_pct
FROM mcss_controls c
LEFT JOIN mcss_audit_results r 
    ON c.control_id = r.control_id 
    AND r.audit_id = 'AUDIT-2025-001';
```
