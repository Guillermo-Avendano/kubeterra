# Incident Notes

This directory documents the production issues investigated in the `ca-12.6.1` workspace and the fixes applied during recovery.

Available documents:

- `recovery-order.md`: Recommended troubleshooting and recovery order for shared storage, PostgreSQL, MobiusView, and ProcessEngine.
- `mobius-incident.md`: Mobius observations, related storage side effects, and the changes applied around shared storage recovery.
- `mobiusview-incident.md`: Root cause analysis for the external `503` on `/mobius/admin`, MobiusView recovery steps, and deploy changes.
- `postgresql-incident.md`: Root cause analysis for the PostgreSQL instability that caused Mobius Admin to stop responding after login.
- `processengine-incident.md`: Root cause analysis for the `Pending` ProcessEngine pod and the storage reconciliation fix.

These notes are intended to be operational documentation for future troubleshooting and redeployments.