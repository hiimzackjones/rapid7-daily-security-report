# Daily Security Report - Example Corp

Generated {{["c13b1d4f-c686-4097-a2dd-3aaf8aa58e52"].[converted_date]}} (ET) | Sources: Rapid7 InsightIDR (MDR), Surface Command, SentinelOne

---

## Recently active endpoints

{{#each ["SC EPP Counts"].[items]}}**{{this.epp_active_24h}}** of **{{this.epp_total}}** endpoints have communicated with SentinelOne in the last 24 hours.

- Stopped reporting (7-15 days): **{{this.epp_attention_7_15d}}**
- Missing telemetry for more than 15 days: **{{this.epp_stale_15d}}**
- Endpoints with active threats: **{{this.epp_infected}}**
- Running an outdated sensor version: **{{this.epp_outdated_agent}}**
- Newly observed endpoints: **{{this.epp_new_24h}}**
{{/each}}

{{#if ["SC EPP Attention"].[items]}}

### Endpoints missing telemetry (7-15 days)
| Endpoint | Type | OS | Last active | Last user |
|---|---|---|---|---|
{{#each ["SC EPP Attention"].[items]}}| **{{this.name}}** | {{this.type}} | {{this.os}} | {{this.last_active}} | {{this.last_user}} |
{{/each}}{{/if}}
{{#if ["SC EPP Stale"].[items]}}

### Endpoints missing telemetry for more than 15 days (up to 20 shown)
| Endpoint | Type | OS | Last active | Last user |
|---|---|---|---|---|
{{#each ["SC EPP Stale"].[items]}}| **{{this.name}}** | {{this.type}} | {{this.os}} | {{this.last_active}} | {{this.last_user}} |
{{/each}}{{/if}}

---

## Threats to your organization

Rapid7 reviewed **{{["Alerts All"].[metadata].[total_items]}}** alerts in the last 24 hours. **{{["Alerts Notable"].[metadata].[total_items]}}** were notable (above informational) and **{{["Alerts Customer"].[metadata].[total_items]}}** required customer attention.

**{{["Inv New"].[metadata].[total_data]}}** new investigations were opened in the last 24 hours.

{{#if ["Inv Open"].[metadata].[total_data]}}You currently have **{{["Inv Open"].[metadata].[total_data]}}** open investigations that require attention.{{else}}No open threats require attention - great job!{{/if}}
{{#if ["Inv New"].[investigations]}}

### New investigations
| Priority | Investigation | Status |
|---|---|---|
{{#each ["Inv New"].[investigations]}}| {{this.priority}} | [**{{this.title}}**](https://REGION.idr.insight.rapid7.com/op/YOUR_PRODUCT_TOKEN#/investigations/{{this.rrn}}) | {{this.status}} |
{{/each}}{{/if}}
{{#if ["Alerts Notable"].[alerts]}}

### Notable alerts
| Priority | Alert |
|---|---|
{{#each ["Alerts Notable"].[alerts]}}| {{this.priority}} | [{{this.title}}](https://REGION.idr.insight.rapid7.com/op/YOUR_PRODUCT_TOKEN#/alerts/{{this.rrn}}) |
{{/each}}{{/if}}
[Open investigations in InsightIDR](https://REGION.idr.insight.rapid7.com/op/YOUR_PRODUCT_TOKEN#/investigations)

---

## Exploitable vulnerabilities - CISA Known Exploited (KEV)

{{#each ["SC KEV Counts"].[items]}}Your environment currently has **{{this.kev_count}}** vulnerabilities on CISA's Known Exploited Vulnerabilities list. **{{this.kev_with_fix}}** of them have a fix available today.
{{/each}}

### Top 10 by Rapid7 Active Risk
| CVE | Severity | CVSS | Active Risk | Fix available |
|---|---|---|---|---|
{{#each ["SC KEV Top"].[items]}}| [**{{this.cve}}**](https://nvd.nist.gov/vuln/detail/{{this.cve}}) | {{this.severity}} | {{this.cvss}} | {{this.active_risk}} | {{#if this.fix_available}}Yes{{/if}} |
{{/each}}

---

_Generated automatically from live Rapid7 platform data (InsightConnect)._
