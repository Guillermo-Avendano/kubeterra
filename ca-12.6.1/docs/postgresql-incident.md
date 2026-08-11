# PostgreSQL Incident Notes

## Summary

After the original Mobius Admin `503` was removed, a second user-visible problem remained:

- `https://services-us-virginia-m-1.skytap.com:433/mobius/admin/` loaded after `admin/admin`
- the application did not respond correctly after login

The root cause was PostgreSQL instability. The PostgreSQL pod was being restarted by the kernel because of memory pressure, which caused MobiusView to lose database connectivity during authenticated application activity.

## Symptoms Observed

- the authenticated Mobius Admin URL returned `HTTP 200`
- the HTML shell for the admin application loaded correctly
- MobiusView logs showed repeated JDBC/Hikari failures
- PostgreSQL connection attempts were refused during admin requests

Representative MobiusView log messages:

- `HikariPool-1 - Connection is not available`
- `Connection to postgresql.contentautomation.svc.cluster.local:5432 refused`

Representative PostgreSQL pod state:

- pod `postgresql-0` restarting multiple times
- `Last State: Terminated`
- `Reason: OOMKilled`
- very low effective runtime memory settings on the live container

## Root Cause

The PostgreSQL chart in this environment was not effectively applying the intended memory settings.

The key findings were:

- the chart uses `primary.resources`, not top-level `resources`, for the main PostgreSQL container
- the live release still had `primary.resources: {}` and `primary.resourcesPreset: nano`
- the live PostgreSQL container also carried `POSTGRESQL_MAX_CONNECTIONS=1000`

That combination caused PostgreSQL to run with a very small memory profile while being configured for an aggressively high connection ceiling.

The result was repeated `OOMKilled` restarts and transient connection refusals seen by MobiusView.

## Files Updated

- `/home/rocket/ca-12.6.1/database/templates/postgres.yaml`

## Configuration Changes Applied

The template was updated so the intended resource settings are placed in the correct chart location:

- `primary.resourcesPreset: none`
- `primary.resources.requests.cpu: 500m`
- `primary.resources.requests.memory: 1Gi`
- `primary.resources.limits.cpu: 1`
- `primary.resources.limits.memory: 2Gi`

The template was also updated to remove the explicit:

- `POSTGRESQL_MAX_CONNECTIONS=1000`

This prevents unnecessary memory pressure from an oversized connection limit.

## Live Recovery Actions Performed

Because the normal Helm upgrade path was blocked during the incident, the effective fix was first applied live to the running cluster:

1. remove `POSTGRESQL_MAX_CONNECTIONS` from the live PostgreSQL `StatefulSet`
2. patch the PostgreSQL container resources on the live `StatefulSet`
3. restart `postgresql-0`
4. wait for PostgreSQL to become `Ready`
5. restart `mobiusview-0` so it rebuilt its JDBC connection pool cleanly

## Verification Result

After the live recovery:

- `postgresql-0` became `1/1 Running`
- PostgreSQL restarted with the larger memory allocation
- `mobiusview-0` became `1/1 Running`
- the authenticated Mobius Admin URL returned `HTTP 200`
- fresh MobiusView logs no longer showed new PostgreSQL connectivity failures after restart

## Operational Note

This incident was different from the original ingress and storage issues.

At this stage:

- routing was already correct
- authentication was already working
- the failure was entirely in the backend database path

If `/mobius/admin/` loads but the application hangs or fails after login, inspect PostgreSQL stability and MobiusView database logs before revisiting ingress.

## Final Status

PostgreSQL is stable again, and Mobius Admin can proceed past the initial authenticated page load.

For the recommended component recovery sequence, see:

- `/home/rocket/ca-12.6.1/docs/recovery-order.md`