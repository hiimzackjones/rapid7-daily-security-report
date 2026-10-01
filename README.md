# Daily Security Report — Rapid7 InsightConnect Workflow

A customer-ready **daily security report email** built entirely from **stock InsightConnect
plugins — zero custom code**. Pulls live data from InsightIDR, Surface Command, and
SentinelOne (via Surface Command's graph), renders it through one Handlebars/Markdown
template, and outputs email-ready HTML.

## What the report contains

| Section | Source | Example |
|---|---|---|
| **Recently active endpoints** | Surface Command (SentinelOne agents) | "627 of 751 endpoints have communicated in the last 24 hours" + stopped-reporting counts |
| **Endpoints missing telemetry** | Surface Command | Two tables: quiet 7–15 days, silent 15+ days — hostname, OS, last active, last user |
| **Threats to your organization** | InsightIDR Alerts + Investigations APIs | "Rapid7 reviewed **489** alerts… **156** notable… **318** required your attention" + clickable investigation/alert deep-links |
| **Exploitable vulnerabilities (CISA KEV)** | Surface Command | KEV count, fix-available count, top 10 by Rapid7 Active Risk with NVD links |

All counts are **server-side** (API `metadata` totals / Cypher aggregates) — none are
computed in templates, because InsightConnect Handlebars has no counting helpers.

## Requirements

- InsightConnect, with these **stock** plugins: `Rapid7 InsightIDR` (≥12.x),
  `Rapid7 Surface Command` (≥1.2), `datetime` (≥3.x), `markdown` (≥4.x)
- **Surface Command** with a SentinelOne connector (asset + agent data in the graph)
- InsightIDR with the **Alerts experience** (v2 Alerts API — present on MDR orgs)
- One Insight Platform **org API key**, and your region code

## Install

1. **Import** `workflow/daily-security-report.snpt` as a snippet.
2. **Re-point connections**: every step shows placeholder connections — select your real
   InsightIDR and Surface Command connections (same org key), and your orchestrator (or
   cloud) for the `datetime`/`markdown` steps.
3. **Nudge the validator**: open any step with a reference (e.g. `Cutoff 24h`), re-insert
   the reference via the variable picker, save. Import-time "can't find variables" errors
   are stale — one save re-validates everything (known ICON import quirk).
4. **Localize the template** (critical, see `tools/localize_template.py` docstring):
   export your imported snippet, run the script, paste the corrected template back into
   `Report HTML`. Without this, block-helper sections render empty.
5. **Set your URLs**: in the template, replace `REGION` and `YOUR_PRODUCT_TOKEN` in the
   InsightIDR deep links (copy the `…idr.insight.rapid7.com/op/<token>` base from your
   browser when logged into InsightIDR).
6. **Run it** and inspect the `Report HTML` step's `html_string` output.
7. **Email delivery**: add your mail plugin (SMTP / O365 / Gmail), body =
   `templates/email-shell.html` with the `REPORT_BODY_GOES_HERE` marker replaced by a
   reference to `Report HTML → html_string`, and `html: true`. Add a Schedule trigger.

## Hard-won implementation notes (read before modifying)

- **Surface Command Cypher dialect**: `datetime()`/`duration()` are **disallowed**
  (function allowlist). Temporal properties are typed datetimes — comparing them to
  strings directly compares **types**, not values (every `>=` true, every `<` false).
  Always compare `toString(prop)` against an ISO string literal. Date formatting is done
  with `substring()` + concatenation. See `queries/sc-queries.cypher`.
- **Dates are injected**: the workflow computes now/−24h/−7d/−15d with the stock
  `datetime` plugin and Handlebars-injects them into adhoc Cypher. Saved queries can't
  take parameters — don't convert these steps to saved queries.
- **Counting**: IDR Search Investigations exposes `metadata.total_data`; Search **Alerts**
  exposes `metadata.total_items` (yes, different names). Both honor filters server-side.
- **Alert term filters**: field ids are `alert.priority` and `alert.responsibility`
  (dotted); operators EQUALS / NOT_EQUALS / CONTAINS.
- **Deep links**: InsightIDR accepts **full RRNs** in URLs
  (`#/investigations/<rrn>`, `#/alerts/<rrn>`); short IDs do not work.
- **Template refs**: the ICON runtime resolves `{{[nodeId]…}}` references. Inline input
  refs are auto-normalized by the builder; refs inside `{{#each}}`/`{{#if}}` are not —
  hence `tools/localize_template.py`.
- **Markdown→HTML** is pandoc-based: pipe tables work but get equal-width `<colgroup>`
  styling — the email shell overrides this (`col { width:auto !important }`).
- **Keep template punctuation ASCII** — copy/paste round-trips through browsers/builders
  can mojibake multibyte punctuation.
- If an EPP health bucket suddenly reads `all/0`, a type/format regression in the date
  comparison is the first suspect (see dialect note above).

## Repo layout

```
workflow/daily-security-report.snpt   importable snippet (15+2 steps, linear chain)
templates/report-template.md          the Handlebars/Markdown report template (portable, name-based refs)
templates/email-shell.html            email-safe styled wrapper for html_string
queries/sc-queries.cypher             annotated Surface Command queries + dialect notes
tools/localize_template.py            binds template refs to your org's nodeIds after import
```

## Customizing

- Thresholds (7/15 days), list caps (top 20 stale, top 10 KEV), and all verbiage are
  plain text in the step inputs/template.
- Extra sections that drop in easily: SentinelOne maintenance (reboot pending /
  user-action-needed properties), decommissioned endpoints (`isDecommissioned` /
  `decommissionedAt` — if your S1 org uses the decommission workflow), weekly trend
  variant, Rapid7 Emergent Threats RSS (RSS trigger + Global Artifact pattern).

## License

MIT
