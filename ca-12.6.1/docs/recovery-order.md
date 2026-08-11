# Recovery Order

## Purpose

This document describes the recommended recovery order for the incidents seen in this environment.

The goal is to restore dependencies in the correct sequence and avoid reintroducing the same failures.

## Recommended Order

1. Validate shared Mobius storage.
2. Validate PostgreSQL stability.
3. Recover MobiusView.
4. Recover ProcessEngine.
5. Retest external Mobius Admin access.

## Step 1: Validate Shared Mobius Storage

Check the shared storage owned by Mobius first:

- `mobius-pv-storage`
- `mobius-diagnostic-pv-storage`
- `mobius-fts-pv-storage`
- `mobius-pv-claim`
- `mobius-diagnostic-pv-claim`
- `mobius-fts-pv-claim`

Typical failure states:

- PV in `Released`
- PVC missing
- PVC stuck with `deletionTimestamp`

Why this comes first:

- MobiusView depends on `mobius-pv-claim`
- MobiusView must not manage that shared claim
- if shared storage is broken, MobiusView recovery will fail or remain incomplete

Recovery owner:

- Mobius

Relevant files:

- `/home/rocket/ca-12.6.1/deploy_mobius.sh`
- `/home/rocket/ca-12.6.1/common/mobius_shared_storage.sh`

## Step 2: Validate PostgreSQL Stability

Once shared storage is healthy, confirm PostgreSQL is stable.

Checks:

- `postgresql-0` is `1/1 Running`
- no recent `OOMKilled` state
- service `postgresql` has a ready endpoint
- MobiusView does not log fresh `Connection to postgresql... refused` errors

Why this comes second:

- MobiusView can serve the HTML shell while still failing after login if PostgreSQL is unstable
- fixing ingress or frontend behavior will not solve backend database failures

Relevant file:

- `/home/rocket/ca-12.6.1/database/templates/postgres.yaml`

## Step 3: Recover MobiusView

Recover MobiusView only after shared storage and PostgreSQL are healthy.

Checks:

- `mobiusview-0` is `1/1 Running`
- service `mobiusview` has a ready endpoint
- no fresh JDBC/Hikari errors in MobiusView logs

Important rule:

- MobiusView validates the shared claim `mobius-pv-claim`
- MobiusView does not own the lifecycle of that claim

Relevant files:

- `/home/rocket/ca-12.6.1/deploy_mobiusview.sh`
- `/home/rocket/ca-12.6.1/mobiusview/templates/mobiusview.yaml`

## Step 4: Recover ProcessEngine

Recover ProcessEngine after the shared platform dependencies are already stable.

Checks:

- `process-pv-claim` is `Bound`
- `contentautomation-processengine` pod is `1/1 Running`

Typical failure states:

- `process-pv-claim` missing
- `process-pv-storage` in `Released`

Relevant file:

- `/home/rocket/ca-12.6.1/deploy_processengine.sh`

## Step 5: Retest External Mobius Admin Access

Only after the previous steps should you retest:

- `https://services-us-virginia-m-1.skytap.com:433/mobius/admin/`

Expected path:

- unauthenticated request returns `401`
- authenticated request returns `200`
- application continues working after login

## Short Decision Guide

- If `/mobius/admin/` returns `503`, inspect MobiusView readiness and shared storage first.
- If `/mobius/admin/` returns `200` but the application hangs after login, inspect PostgreSQL next.
- If ProcessEngine is `Pending`, inspect `process-pv-claim` and `process-pv-storage`.

## Principle

Recover dependencies from the bottom up:

- shared storage
- database
- application backend
- dependent services
- external entrypoint