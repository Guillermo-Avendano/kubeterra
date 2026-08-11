# ProcessEngine Incident Notes

## Summary

The pod `contentautomation-processengine-f475f895d-xv22z` was stuck in `Pending` because its required PVC did not exist anymore, while the backing PV had been left in `Released` state.

This was a storage lifecycle problem, not an application image or database configuration problem.

## Symptoms Observed

- Pod status: `Pending`
- Scheduler could not place the pod on any node
- `describe pod` showed repeated scheduling failures

Key scheduler messages:

- `persistentvolumeclaim "process-pv-claim" is being deleted`
- `persistentvolumeclaim "process-pv-claim" not found`

## Root Cause

The ProcessEngine deployment mounts `process-pv-claim`, but the following live state was found:

- PVC `process-pv-claim` did not exist anymore
- PV `process-pv-storage` still existed
- PV `process-pv-storage` was in `Released`

That combination prevents Kubernetes from scheduling the pod because the declared volume cannot be mounted.

## Changes Applied

File updated:

- `/home/rocket/ca-12.6.1/deploy_processengine.sh`

New logic added:

- detect whether `process-pv-storage` is in `Released`
- detect whether `process-pv-claim` is missing
- detect whether `process-pv-claim` has a `deletionTimestamp`
- delete stale ProcessEngine PV/PVC resources when needed
- wait for old PV removal before recreating storage
- recreate storage before Helm deploy

## Live Recovery Steps Performed

The recovery sequence was:

1. remove stale ProcessEngine PV/PVC objects
2. recreate `process-pv-storage`
3. recreate `process-pv-claim`
4. redeploy ProcessEngine
5. verify that the original deployment pod becomes runnable again

## Important Operational Note

During the recovery, a separate Helm release named `processengine` was created while the original active deployment was still `contentautomation-processengine` from the main `contentautomation` release.

That duplicate release was removed after verification to avoid leaving two ProcessEngine deployments in the namespace.

## Verification Result

After storage recovery:

- `process-pv-claim` became `Bound`
- `process-pv-storage` became `Bound`
- `contentautomation-processengine-f475f895d-xv22z` became `1/1 Running`

## Final Status

ProcessEngine is no longer blocked by storage scheduling issues.

Future redeploys can now recover automatically from the common stale storage states that caused this incident.

For the recommended component recovery sequence, see:

- `/home/rocket/ca-12.6.1/docs/recovery-order.md`