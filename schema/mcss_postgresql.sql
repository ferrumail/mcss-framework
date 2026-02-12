-- MCSS PostgreSQL Schema
-- Mailserver Configuration Scoring System
-- 
-- Usage: psql -d mcss_audit -f mcss_postgresql.sql
--        or via import_mcss_controls.pl -c

BEGIN;

-- Main controls table
CREATE TABLE IF NOT EXISTS mcss_controls (
    id SERIAL PRIMARY KEY,
    control_id VARCHAR(20) NOT NULL UNIQUE,
    area VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    
    -- Exploitability metrics
    exposure_vector CHAR(1) NOT NULL CHECK (exposure_vector IN ('N','A','L','P')),
    attack_complexity CHAR(1) NOT NULL CHECK (attack_complexity IN ('L','H')),
    attack_requirements CHAR(1) NOT NULL CHECK (attack_requirements IN ('N','P')),
    privileges_required CHAR(1) NOT NULL CHECK (privileges_required IN ('N','L','H')),
    user_interaction CHAR(1) NOT NULL CHECK (user_interaction IN ('N','P','A')),
    
    -- Impact metrics
    confidentiality_impact CHAR(1) NOT NULL CHECK (confidentiality_impact IN ('N','L','H')),
    integrity_impact CHAR(1) NOT NULL CHECK (integrity_impact IN ('N','L','H')),
    availability_impact CHAR(1) NOT NULL CHECK (availability_impact IN ('N','L','H')),
    
    -- Supplemental
    remediation_complexity CHAR(1) NOT NULL CHECK (remediation_complexity IN ('T','S','M','C','A')),
    
    -- Reference
    evidence_file VARCHAR(255),
    
    -- Computed scores (populated by trigger or application)
    exploitability_score NUMERIC(3,2),
    impact_score NUMERIC(3,2),
    base_score NUMERIC(3,1),
    severity VARCHAR(10),
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_controls_area ON mcss_controls(area);
CREATE INDEX IF NOT EXISTS idx_controls_severity ON mcss_controls(severity);
CREATE INDEX IF NOT EXISTS idx_controls_base_score ON mcss_controls(base_score DESC);

-- Audit findings table (results for a specific audit)
CREATE TABLE IF NOT EXISTS mcss_findings (
    id SERIAL PRIMARY KEY,
    audit_id UUID NOT NULL,
    control_id VARCHAR(20) NOT NULL REFERENCES mcss_controls(control_id),
    
    -- Finding status
    status VARCHAR(20) NOT NULL CHECK (status IN ('pass','fail','partial','na','error')),
    
    -- Details
    evidence TEXT,
    notes TEXT,
    
    -- Timestamp
    assessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_findings_audit ON mcss_findings(audit_id);
CREATE INDEX IF NOT EXISTS idx_findings_status ON mcss_findings(status);

-- Audit session table
CREATE TABLE IF NOT EXISTS mcss_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hostname VARCHAR(255) NOT NULL,
    audit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    auditor VARCHAR(100),
    
    -- Scope
    mta_type VARCHAR(20),
    mda_type VARCHAR(20),
    
    -- Summary (computed)
    total_controls INTEGER,
    controls_passed INTEGER,
    controls_failed INTEGER,
    controls_na INTEGER,
    average_score NUMERIC(3,1),
    
    -- Metadata
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Summary by area view
CREATE OR REPLACE VIEW mcss_summary_by_area AS
SELECT 
    area,
    COUNT(*) as total_controls,
    COUNT(*) FILTER (WHERE severity = 'Critical') as critical,
    COUNT(*) FILTER (WHERE severity = 'High') as high,
    COUNT(*) FILTER (WHERE severity = 'Medium') as medium,
    COUNT(*) FILTER (WHERE severity = 'Low') as low,
    ROUND(AVG(base_score), 1) as avg_score
FROM mcss_controls
GROUP BY area
ORDER BY avg_score DESC;

-- Critical controls view
CREATE OR REPLACE VIEW mcss_critical_controls AS
SELECT 
    control_id,
    area,
    description,
    base_score,
    severity,
    remediation_complexity,
    evidence_file
FROM mcss_controls
WHERE base_score >= 9.0
ORDER BY base_score DESC, area;

-- Remediation priority view
CREATE OR REPLACE VIEW mcss_remediation_priority AS
SELECT 
    control_id,
    area,
    description,
    base_score,
    severity,
    remediation_complexity,
    -- Weighted score: high severity + low complexity = high priority
    ROUND(
        base_score * 
        CASE remediation_complexity 
            WHEN 'T' THEN 1.5  -- Trivial: bonus
            WHEN 'S' THEN 1.3  -- Simple: bonus
            WHEN 'M' THEN 1.0  -- Moderate: neutral
            WHEN 'C' THEN 0.8  -- Complex: penalty
            WHEN 'A' THEN 0.5  -- Architectural: high penalty
        END
    , 1) as priority_score
FROM mcss_controls
WHERE base_score >= 4.0
ORDER BY priority_score DESC;

-- Function to calculate score from metrics
CREATE OR REPLACE FUNCTION mcss_calculate_scores(
    p_ev CHAR(1), p_ac CHAR(1), p_ar CHAR(1), p_pr CHAR(1), p_ui CHAR(1),
    p_vc CHAR(1), p_vi CHAR(1), p_va CHAR(1)
) RETURNS TABLE (
    exploitability NUMERIC,
    impact NUMERIC,
    base_score NUMERIC,
    severity VARCHAR
) AS $$
DECLARE
    v_ev NUMERIC;
    v_ac NUMERIC;
    v_ar NUMERIC;
    v_pr NUMERIC;
    v_ui NUMERIC;
    v_vc NUMERIC;
    v_vi NUMERIC;
    v_va NUMERIC;
    v_exploitability NUMERIC;
    v_impact NUMERIC;
    v_base NUMERIC;
    v_severity VARCHAR;
BEGIN
    -- Exposure Vector weights
    v_ev := CASE p_ev WHEN 'N' THEN 0.0 WHEN 'A' THEN 0.1 WHEN 'L' THEN 0.2 WHEN 'P' THEN 0.3 END;
    v_ac := CASE p_ac WHEN 'L' THEN 0.0 WHEN 'H' THEN 0.1 END;
    v_ar := CASE p_ar WHEN 'N' THEN 0.0 WHEN 'P' THEN 0.1 END;
    v_pr := CASE p_pr WHEN 'N' THEN 0.0 WHEN 'L' THEN 0.1 WHEN 'H' THEN 0.2 END;
    v_ui := CASE p_ui WHEN 'N' THEN 0.0 WHEN 'P' THEN 0.1 WHEN 'A' THEN 0.2 END;
    
    -- Impact weights (inverted: H=0.0 means high impact)
    v_vc := CASE p_vc WHEN 'H' THEN 0.0 WHEN 'L' THEN 0.1 WHEN 'N' THEN 0.2 END;
    v_vi := CASE p_vi WHEN 'H' THEN 0.0 WHEN 'L' THEN 0.1 WHEN 'N' THEN 0.2 END;
    v_va := CASE p_va WHEN 'H' THEN 0.0 WHEN 'L' THEN 0.1 WHEN 'N' THEN 0.2 END;
    
    -- Calculate exploitability (0-1)
    v_exploitability := 1.0 - (v_ev + v_ac + v_ar + v_pr + v_ui) / 0.9;
    
    -- Calculate impact components
    DECLARE
        vc_impact NUMERIC := 1.0 - (v_vc / 0.2);
        vi_impact NUMERIC := 1.0 - (v_vi / 0.2);
        va_impact NUMERIC := 1.0 - (v_va / 0.2);
    BEGIN
        v_impact := 1.0 - ((1.0 - vc_impact) * (1.0 - vi_impact) * (1.0 - va_impact));
    END;
    
    -- Calculate base score
    v_base := ROUND(10.0 * (1.0 - (1.0 - v_exploitability) * (1.0 - v_impact)), 1);
    
    -- Determine severity
    v_severity := CASE 
        WHEN v_base >= 9.0 THEN 'Critical'
        WHEN v_base >= 7.0 THEN 'High'
        WHEN v_base >= 4.0 THEN 'Medium'
        WHEN v_base >= 0.1 THEN 'Low'
        ELSE 'None'
    END;
    
    RETURN QUERY SELECT 
        ROUND(v_exploitability, 2),
        ROUND(v_impact, 2),
        v_base,
        v_severity;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Trigger for automatic score calculation
CREATE OR REPLACE FUNCTION mcss_update_scores()
RETURNS TRIGGER AS $$
DECLARE
    scores RECORD;
BEGIN
    SELECT * INTO scores FROM mcss_calculate_scores(
        NEW.exposure_vector, NEW.attack_complexity, NEW.attack_requirements,
        NEW.privileges_required, NEW.user_interaction,
        NEW.confidentiality_impact, NEW.integrity_impact, NEW.availability_impact
    );
    
    NEW.exploitability_score := scores.exploitability;
    NEW.impact_score := scores.impact;
    NEW.base_score := scores.base_score;
    NEW.severity := scores.severity;
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mcss_update_scores ON mcss_controls;
CREATE TRIGGER trg_mcss_update_scores
    BEFORE INSERT OR UPDATE ON mcss_controls
    FOR EACH ROW
    EXECUTE FUNCTION mcss_update_scores();

COMMIT;

-- Comments
COMMENT ON TABLE mcss_controls IS 'MCSS security controls with scoring metrics';
COMMENT ON TABLE mcss_findings IS 'Results of applying controls to a specific audit';
COMMENT ON TABLE mcss_audits IS 'Audit session metadata';
COMMENT ON VIEW mcss_summary_by_area IS 'Control count and average score by area';
COMMENT ON VIEW mcss_critical_controls IS 'Controls with Critical severity (score >= 9.0)';
COMMENT ON VIEW mcss_remediation_priority IS 'Controls prioritized by severity and remediation effort';
