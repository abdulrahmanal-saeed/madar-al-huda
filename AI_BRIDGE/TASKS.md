# Active task board — Phase 0

Project-level roadmap and statuses: [../plan/README.md](../plan/README.md) and [../plan/TRACKER.md](../plan/TRACKER.md). This bridge tracks only active agent handoffs; if stale, update it to match the tracker.

| ID | Task | Owner | Status | Acceptance |
|---|---|---|---|---|
| MHD-000 | Establish repo and specification baseline | ChatGPT | DONE | Docs, branch, PR exist and links verified |
| MHD-001 | Build Flutter Android skeleton with Arabic/English (`P00-06`) | Coding agent (Claude Code) | REVIEW | Debug build, navigation, RTL/LTR smoke tests — implemented on branch `claude/serene-galileo-f2ia01`, [PR #4](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/4) merged. Pending device/emulator AR/EN and TalkBack/copy checks; see IMPLEMENTATION.md |
| MHD-009 | Architecture/ERD/RLS design review (`P00-05`) | ChatGPT | DONE | [Issue #13](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/13); architecture pack merged via [PR #14](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/14); no live database deployment |
| MHD-010 | Identity source and launcher assets (`P00-03`) | ChatGPT | DONE | [Issue #15](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/15), Existing SVG/wordmarks/icons unchanged and approved by owner 2026-11-22; only legal R-10 remains for store release |
| MHD-002 | Verify Quran source and legal edition | Content lead | BLOCKED | Rights log, attribution, fixed checksum |
| MHD-003 | Official prayer references / TZ groundwork (`P00-10`) | ChatGPT | IN_PROGRESS | [Issue #21](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/21): ESA Cairo/Alexandria source times and zoneinfo checks; UAE authoritative values and actual prayer calculations still pending |
| MHD-004 | Route-aligned bilingual wireframes (`P00-04`) | ChatGPT | REVIEW | [Issue #18](https://github.com/abdulrahmanal-saeed/madar-al-huda/issues/18): 14 source SVGs and UX spec; source checker added to existing CI; pending review |
| MHD-005 | Verify reciter and tafsir distribution rights | Content lead | BLOCKED | 3 reciters and 2 tafsir sources assessed |
| MHD-006 | Define fiqh reviewer workflow | Content lead | BLOCKED | Qualified reviewer and approval gates documented |
| MHD-008 | Dev update channel: signed dev APK on GitHub prereleases + Obtainium (`P00-11`) | Coding agent (Claude Code) | REVIEW | Workflow after green CI on main; fixed dev key via secrets; `.dev` app id; docs/DEV_UPDATES.md — branch `phase-00/p00-11-dev-updates`, [PR #6](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/6) merged; pending signing secrets and first published APK/Obtainium update |
| MHD-007 | QA rules, Definition of Done, PR template (`P00-09`) | Coding agent (Claude Code) | DONE | DoD per task type, manual QA checklist, PR template; no duplicate CI — branch `phase-00/p00-09-qa-dod`, [PR #5](https://github.com/abdulrahmanal-saeed/madar-al-huda/pull/5) merged |

## Execution rules
- Explicit owner, branch, tests and reviewer comments for each task.
- Never infer content reuse rights from public web availability.
- Keep unfinished or blocked tasks clearly labeled.
