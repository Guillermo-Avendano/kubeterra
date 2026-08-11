# Mobius Incident Notes

## Summary

Mobius itself was not the direct cause of the external `503` observed on `https://services-us-virginia-m-1.skytap.com:433/mobius/admin`.

The main service impact came from MobiusView not becoming ready. However, Mobius shared storage was part of the recovery path because MobiusView depends on the shared claim `mobius-pv-claim`.

## Symptoms Observed

- `mobius-0` was running and reported `1/1 Ready`.
- Mobius logs included an authorization utility warning:
  - `AuthorizationUpdateUtility` failed with `401` while trying to access the user list.
- The log message suggested a possible Mobius authorization problem, but it did not stop the pod from becoming healthy.
- Later in the recovery, Mobius shared PVCs were found in a broken lifecycle state and blocked MobiusView scheduling.

## Important Finding

The `401` in Mobius logs was not the outage root cause.

The real issue was that shared Mobius PVC/PV resources had entered an inconsistent state:

- some PVCs were marked for deletion
- some PVs were in `Released`
- MobiusView needed the shared claim `mobius-pv-claim`

As a result, Mobius could remain healthy while MobiusView could not be scheduled.

## Shared Storage Ownership

The shared claim `mobius-pv-claim` must remain shared between Mobius and MobiusView.

The correct ownership model is:

- Mobius owns the lifecycle of the shared storage
- Mobius creates and repairs `mobius-pv-claim`
- MobiusView consumes the claim but must not delete or recreate it

This is important because `mobius-pv-claim` is not a MobiusView-specific volume. It is a shared application dependency.

## Storage Problems Identified

The following shared Mobius storage objects were part of the recovery work:

- `mobius-pv-storage`
- `mobius-diagnostic-pv-storage`
- `mobius-fts-pv-storage`
- `mobius-pv-claim`
- `mobius-diagnostic-pv-claim`
- `mobius-fts-pv-claim`

The main failure modes were:

- PV in `Released`
- PVC missing
- PVC stuck with `deletionTimestamp`

## Changes Applied

The deploy script was enhanced to recover stale storage automatically before redeploying Mobius.

File updated:

- `/home/rocket/ca-12.6.1/deploy_mobius.sh`

Key logic added or kept during the recovery work:

- shared storage logic moved to `/home/rocket/ca-12.6.1/common/mobius_shared_storage.sh`
- detect `Released` state on Mobius shared PVs
- detect missing Mobius shared PVCs
- detect PVCs already marked for deletion
- delete stale PV/PVC objects when necessary
- wait until stale PVs are fully removed before recreating storage

## Operational Result

After the storage objects were recreated and rebound:

- Mobius shared storage became usable again
- MobiusView could mount the shared claim it needed
- Mobius remained healthy throughout the final state

## Final Status

- `mobius-0` healthy
- shared Mobius PVCs rebound
- no longer blocking MobiusView startup

## Recommendation

If MobiusView cannot be scheduled but Mobius is healthy, inspect Mobius shared storage first before assuming the Mobius authorization warnings are the root cause.

Do not let MobiusView manage the lifecycle of `mobius-pv-claim`. MobiusView should only validate that the shared claim exists and is healthy.

See also:

- `/home/rocket/ca-12.6.1/docs/recovery-order.md`