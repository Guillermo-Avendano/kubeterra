#!/bin/bash

reconcile_mobius_shared_storage() {
	local reset_storage=false
	local pv_name=''
	local pvc_name=''
	local phase=''
	local deleting=''

	for pv_name in mobius-pv-storage mobius-diagnostic-pv-storage mobius-fts-pv-storage; do
		phase=$($KUBE_CLI_EXE get pv "$pv_name" -o jsonpath='{.status.phase}' 2>/dev/null || true)
		if [ "$phase" == "Released" ]; then
			reset_storage=true
			break
		fi
	done

	for pvc_name in mobius-pv-claim mobius-diagnostic-pv-claim mobius-fts-pv-claim; do
		if ! $KUBE_CLI_EXE get pvc "$pvc_name" -n "$NAMESPACE" >/dev/null 2>&1; then
			reset_storage=true
			break
		fi
		deleting=$($KUBE_CLI_EXE get pvc "$pvc_name" -n "$NAMESPACE" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)
		if [ -n "$deleting" ]; then
			reset_storage=true
			break
		fi
	done

	if [ "$reset_storage" == "true" ]; then
		info_message "Resetting stale mobius shared storage resources";
		$KUBE_CLI_EXE delete pvc mobius-pv-claim mobius-diagnostic-pv-claim mobius-fts-pv-claim -n "$NAMESPACE" --ignore-not-found=true
		$KUBE_CLI_EXE delete pv mobius-pv-storage mobius-diagnostic-pv-storage mobius-fts-pv-storage --ignore-not-found=true
		until ! $KUBE_CLI_EXE get pv mobius-pv-storage >/dev/null 2>&1 && ! $KUBE_CLI_EXE get pv mobius-diagnostic-pv-storage >/dev/null 2>&1 && ! $KUBE_CLI_EXE get pv mobius-fts-pv-storage >/dev/null 2>&1; do
			sleep 2
		done
	fi
}

validate_mobius_shared_storage() {
	local deleting=''
	local phase=''

	if ! $KUBE_CLI_EXE get pvc mobius-pv-claim -n "$NAMESPACE" >/dev/null 2>&1; then
		echo "FATAL: Shared PVC mobius-pv-claim is missing. Deploy or recover Mobius shared storage before deploying MobiusView."
		exit 1
	fi

	deleting=$($KUBE_CLI_EXE get pvc mobius-pv-claim -n "$NAMESPACE" -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)
	if [ -n "$deleting" ]; then
		echo "FATAL: Shared PVC mobius-pv-claim is being deleted. Recover Mobius shared storage before deploying MobiusView."
		exit 1
	fi

	phase=$($KUBE_CLI_EXE get pvc mobius-pv-claim -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || true)
	if [ "$phase" != "Bound" ]; then
		echo "FATAL: Shared PVC mobius-pv-claim is not Bound. Current phase: ${phase:-unknown}. Recover Mobius shared storage before deploying MobiusView."
		exit 1
	fi
}