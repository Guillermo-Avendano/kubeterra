# MobiusView Incident Notes

## Summary

MobiusView was the direct cause of the external `503` returned by:

- `https://services-us-virginia-m-1.skytap.com:433/mobius/admin`

Ingress and service routing were correct, but the `mobiusview` service had no ready backend endpoint at the beginning of the investigation.

## Symptoms Observed

- External request returned `503`.
- Ingress `mobiusingress` was configured correctly for host and path.
- Service `mobiusview` existed.
- Endpoints for `mobiusview` showed `notReadyAddresses` instead of ready endpoints.
- `mobiusview-0` failed to become ready.

## Root Causes

### 1. PostgreSQL dependency was unavailable

MobiusView initially failed because PostgreSQL was unavailable.

Observed effects:

- PostgreSQL service existed but had no working backend at one stage.
- MobiusView logs showed database connectivity failures.
- MobiusView could not finish startup while the database was down.

This problem later reappeared in a different form after the external `503` had already been fixed.

At that point:

- the `/mobius/admin/` HTML page loaded successfully after `admin/admin`
- the application still became unusable after login
- MobiusView logs showed repeated JDBC failures and `Connection to postgresql... refused`

The second-stage failure was caused by PostgreSQL instability rather than ingress or frontend asset delivery.

### 2. MobiusView storage resources were stale

MobiusView storage resources had lifecycle issues similar to other components:

- PVs in `Released`
- PVCs missing or marked for deletion

Affected storage objects:

- `mobiusview-presentation-storage`
- `mobiusview-diagnostic-pv-storage`
- `mobiusview-presentation-claim`
- `mobiusview-diagnostic-pv-claim`

### 3. Mobius shared storage was also required

MobiusView also depends on the shared claim `mobius-pv-claim`.

Even after MobiusView-specific storage was repaired, the pod still depended on shared Mobius storage being recreated correctly.

MobiusView must not own that shared claim. It should only validate that the claim exists and is `Bound` before deployment.

### 4. Missing repository initialization and license handling in this tree

Compared with the known-good tree in `/home/rocket/mobius-kube-12.6.1`, the `ca-12.6.1` tree was missing two important MobiusView deployment elements:

- `initRepository` block in the values file
- license secret template and deploy logic

These differences were restored without importing Kafka or EventAnalytics settings.

## Changes Applied

### Deploy script changes

File updated:

- `/home/rocket/ca-12.6.1/deploy_mobiusview.sh`

Applied changes:

- kept and used storage reconciliation logic for stale MobiusView PV/PVC resources
- added validation that shared Mobius storage is present and healthy before deploying MobiusView
- restored license secret generation when `LICENSE_KEY` is present
- restored creation and application of the `mobius-license` secret
- preserved the current tree's non-Kafka and non-EventAnalytics behavior

Shared storage validation now comes from:

- `/home/rocket/ca-12.6.1/common/mobius_shared_storage.sh`

### Values file changes

File updated:

- `/home/rocket/ca-12.6.1/mobiusview/templates/mobiusview.yaml`

Applied changes:

- restored `initRepository`
- kept existing JWT/security settings already used by `ca-12.6.1`
- did not add Kafka bootstrap configuration
- did not add EventAnalytics discovery configuration

### New secret template added

File added:

- `/home/rocket/ca-12.6.1/mobiusview/secrets/templates/mobius-license.yaml`

Purpose:

- creates the `mobius-license` Kubernetes secret from `LICENSE_KEY`

## Probe and Helm Notes

During recovery, the live `StatefulSet` had an invalid probe configuration because HTTP probes from the chart had previously been mixed with a manually patched `tcpSocket` probe.

This caused a failed Helm upgrade at one stage. Even so, the running pod was later confirmed healthy and the service endpoint became ready again.

## Post-Login Failure After Initial Recovery

After the first recovery, the authenticated URL returned `HTTP 200` and served the Mobius Admin HTML page, but the application still did not respond correctly after login.

The investigation showed:

- ingress was healthy
- MobiusView was serving the frontend shell
- the failure moved to backend API/database activity after login

MobiusView logs showed repeated errors such as:

- `HikariPool-1 - Connection is not available`
- `Connection to postgresql.contentautomation.svc.cluster.local:5432 refused`

The root cause was PostgreSQL being repeatedly restarted by `OOMKilled`.

Once PostgreSQL was stabilized and MobiusView was restarted, the post-login path recovered.

## Verification Result

After recovery:

- `mobiusview-0` became `1/1 Running`
- service `mobiusview` exposed a ready endpoint
- external URL no longer returned `503`
- external URL returned `401`, which is the expected authentication challenge from ingress basic auth
- authenticated access to `/mobius/admin/` returned `HTTP 200`
- MobiusView stopped logging fresh PostgreSQL connection failures after PostgreSQL recovery and pod restart

Example verification result:

- `HTTP/2 401`
- `www-authenticate: Basic realm="Authentication Required - admin"`

## Final Status

MobiusView recovery resolved the original customer-facing problem.

The external URL is now reachable, protected by authentication, and able to serve the admin application after login instead of failing with `503` or stalling on database connectivity.

For the PostgreSQL-specific details of the post-login incident, see:

- `/home/rocket/ca-12.6.1/docs/postgresql-incident.md`

For the recommended recovery sequence across components, see:

- `/home/rocket/ca-12.6.1/docs/recovery-order.md`