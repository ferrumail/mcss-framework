# Example: SQL Queries for Analysis

After importing controls with `import_mcss_controls.pl`, you can use these queries.

## Basic Queries

### Critical controls

```sql
SELECT control_id, control_name, base_score, vector_string
FROM mcss_controls
WHERE severity = 'Critical'
ORDER BY base_score DESC;
```

### Summary by area

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

### Severity distribution

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

## Advanced Queries

### Controls by remediation complexity

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

### Quick wins: high impact, easy remediation

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

### Controls requiring Network access (remotely exploitable)

```sql
SELECT control_id, control_name, base_score, severity
FROM mcss_controls
WHERE ev = 'N'  -- Exposure Vector = Network
  AND base_score >= 7.0
ORDER BY base_score DESC;
```

### Controls with confidentiality impact

```sql
SELECT control_id, control_name, base_score
FROM mcss_controls
WHERE vc = 'H'  -- Confidentiality Impact = High
ORDER BY base_score DESC;
```

## Using with Audit Results

### Insert audit result

```sql
INSERT INTO mcss_audit_results 
    (audit_id, hostname, control_id, status, finding, evidence)
VALUES 
    ('AUDIT-2025-001', 'mail.example.com', 'POSTFIX-003', 'Fail', 
     'mynetworks includes overly broad subnet', 
     'mynetworks = 10.0.0.0/8');
```

### Audit report: failed controls

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

### Overall audit score

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

### Weighted risk score

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
