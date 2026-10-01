#!/usr/bin/env python3
"""Bind the report template's step references to YOUR org's nodeIds.

Why: when you import the snippet, InsightConnect assigns fresh nodeIds to every
step. Inline references (step inputs) are normalized automatically when you open
and re-save the steps, but references inside Handlebars block helpers
({{#each ...}} / {{#if ...}}) are NOT normalized and resolve to nothing at
runtime, silently rendering empty sections.

Fix: after importing and saving the snippet once, export it again and run:

    python3 localize_template.py "Your Exported Snippet.snpt"

This prints a corrected template (all refs bound to your org's real nodeIds).
Paste it into the `markdown_string` input of the "Report HTML" step (and into
your Artifact step's content, if you added one). Re-run this any time you
re-import the snippet.
"""
import json, re, sys

if len(sys.argv) != 2:
    sys.exit(__doc__)

snippet = json.load(open(sys.argv[1]))
name2id = {s["name"]: s["nodeId"] for s in snippet["steps"]}
targets = []
for s in snippet["steps"]:
    if s["name"] == "Report HTML":
        targets.append(("Report HTML -> markdown_string", s["metadata"]["parameters"]["input"]["markdown_string"]))
    if s.get("type") == "artifact":
        targets.append((f"artifact step '{s['name']}' -> content", s["metadata"]["parameters"]["input"]["content"]))
text = None

def bind(m):
    prefix, name = m.group(1) or "", m.group(2)
    if name in name2id:
        return "{{" + prefix + "[" + name2id[name] + "]"
    return m.group(0)  # already a nodeId or unknown -> leave untouched

for label, text in targets:
    fixed = re.sub(r'\{\{(#each |#if )?\["([^"]+)"\]', bind, text)
    leftover = re.findall(r'\{\{(?:#each |#if )?\["([^"]+)"\]', fixed)
    print(f"===== PASTE INTO: {label} =====")
    print(fixed)
    print()
    if leftover:
        sys.stderr.write(f"WARNING [{label}]: unresolved step names: {sorted(set(leftover))}\n")
sys.stderr.write("\nDone. Paste each block into the step named in its header.\n")
