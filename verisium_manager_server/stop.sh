#!/usr/bin/env bash
# Stop your Verisium Manager server, then its database.
cd "$(dirname "$0")"; source ./config.sh
[[ $(hostname -s) == "$VMGR_HOST" ]] || exec ssh -t "$VMGR_FQDN" "$PWD/$(basename "$0")" "$@"
set +u; source /apps/settings >/dev/null 2>&1
"$VMGR_ADMIN/vmgrserver" -profile "$VMGR_PROFILE" -stop
"$VMGR_ADMIN/vmgrdb" -stop -db_dir "$VMGR_DB_DIR"
rm -f cds.lib
