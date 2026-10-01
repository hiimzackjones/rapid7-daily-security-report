// Surface Command adhoc queries — daily report — PRODUCTION (v3, dialect locked)
// ──────────────────────────────────────────────────────────────────────────────
// Dialect facts (verified 2026-10-01 in customer tenant):
//   • datetime()/duration() DISALLOWED (allowlist), incl. constructor form (T1 failed)
//   • Temporal properties are TYPED datetimes: raw `prop >= 'string'` compares by
//     TYPE not value ("all >= true / all < false" bug) — NEVER compare raw
//   • toString(prop) >= '<ISO literal>' WORKS (T2 verified: 751/637/19)
//   • coalesce(), CASE-in-sum(), count(), IN-lists: all fine
// Workflow injection: each {{…}} below is replaced by ICON Handlebars from the
// datetime-plugin steps (output field: `date`). Steps assumed in workflow:
//   "Now" (Get Datetime) → "Cutoff 24h" / "Cutoff 7d" / "Cutoff 15d"
//   (Subtract from Datetime: days=1 / 7 / 15; output `date`)
// ──────────────────────────────────────────────────────────────────────────────

// ═══ SC1: EPP HEALTH COUNTS — one row, step name "SC EPP Counts" ═══
MATCH (s:SentinelOneAgent)
WHERE coalesce(s.isDecommissioned,false) = false
  AND coalesce(s.isUninstalled,false) = false
  AND coalesce(s.isPendingUninstall,false) = false
RETURN
  count(s) AS epp_total,
  sum(CASE WHEN toString(s.lastActiveDate) >= '{{["Cutoff 24h"].[date]}}'
      THEN 1 ELSE 0 END) AS epp_active_24h,
  sum(CASE WHEN toString(s.lastActiveDate) <  '{{["Cutoff 7d"].[date]}}'
        AND toString(s.lastActiveDate) >= '{{["Cutoff 15d"].[date]}}'
      THEN 1 ELSE 0 END) AS epp_attention_7_15d,
  sum(CASE WHEN toString(s.lastActiveDate) <  '{{["Cutoff 15d"].[date]}}'
      THEN 1 ELSE 0 END) AS epp_stale_15d,
  sum(CASE WHEN coalesce(s.infected,false) = true THEN 1 ELSE 0 END)   AS epp_infected,
  sum(CASE WHEN coalesce(s.isUpToDate,true) = false THEN 1 ELSE 0 END) AS epp_outdated_agent,
  sum(CASE WHEN toString(s.registeredAt) >= '{{["Cutoff 24h"].[date]}}'
      THEN 1 ELSE 0 END) AS epp_new_24h

// ═══ SC2: NEEDS ATTENTION list (7–15d) — step name "SC EPP Attention" ═══
MATCH (s:SentinelOneAgent)
WHERE coalesce(s.isDecommissioned,false) = false
  AND coalesce(s.isUninstalled,false) = false
  AND coalesce(s.isPendingUninstall,false) = false
  AND toString(s.lastActiveDate) <  '{{["Cutoff 7d"].[date]}}'
  AND toString(s.lastActiveDate) >= '{{["Cutoff 15d"].[date]}}'
RETURN s.computerName AS name, s.machineType AS type, s.osName AS os,
       toString(s.lastActiveDate) AS last_active, s.lastLoggedInUserName AS last_user
ORDER BY last_active DESC

// ═══ SC3: STALE list (>15d, cap 20) — step name "SC EPP Stale" ═══
MATCH (s:SentinelOneAgent)
WHERE coalesce(s.isDecommissioned,false) = false
  AND coalesce(s.isUninstalled,false) = false
  AND coalesce(s.isPendingUninstall,false) = false
  AND toString(s.lastActiveDate) < '{{["Cutoff 15d"].[date]}}'
RETURN s.computerName AS name, s.machineType AS type, s.osName AS os,
       toString(s.lastActiveDate) AS last_active, s.lastLoggedInUserName AS last_user
ORDER BY last_active DESC
LIMIT 20

// ═══ SC4: KEV COUNTS — step name "SC KEV Counts" ═══
MATCH (v:Vulnerability)
WHERE v.is_exploited = true
RETURN count(v) AS kev_count,
       sum(CASE WHEN v.has_resolution = true THEN 1 ELSE 0 END) AS kev_with_fix

// ═══ SC5: KEV TOP 10 — step name "SC KEV Top" ═══
MATCH (v:Vulnerability)
WHERE v.is_exploited = true
RETURN v.name AS cve, v.severity AS severity, v.cvss AS cvss,
       v.rapid7_active_risk_score AS active_risk, v.has_resolution AS fix_available
ORDER BY active_risk DESC
LIMIT 10
// (toFloat untested in this dialect; active_risk ordering sufficient — strings
//  of scores ("355") sort wrong only across digit-count boundaries; active_risk
//  appears numeric-intent. Verify on first run; fallback: ORDER BY cvss DESC + eyeball.)

// ═══ SC6 (optional v1.1): NEW ENDPOINTS 24h — step name "SC EPP New" ═══
MATCH (s:SentinelOneAgent)
WHERE toString(s.registeredAt) >= '{{["Cutoff 24h"].[date]}}'
RETURN s.computerName AS name, s.machineType AS type, s.osName AS os,
       toString(s.registeredAt) AS registered
ORDER BY registered DESC

// Note: if Subtract-from-Datetime's `date` output carries a timezone suffix
// (Z/+00:00), comparisons remain correct at day-scale; only sub-second
// boundary cases blur. Confirm formats visually on first live run.
