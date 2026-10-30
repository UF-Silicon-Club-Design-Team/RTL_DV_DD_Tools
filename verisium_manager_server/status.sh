#!/usr/bin/env bash
# Is your database / server running?
cd "$(dirname "$0")"; source ./config.sh
[[ $(hostname -s) == "$VMGR_HOST" ]] || exec ssh -t "$VMGR_FQDN" "$PWD/$(basename "$0")" "$@"
set +u; source /apps/settings >/dev/null 2>&1
echo -n "Database: "; "$VMGR_ADMIN/vmgrdb" -status -db_dir "$VMGR_DB_DIR" 2>&1 | head -1
echo -n "Server:   "; "$VMGR_ADMIN/vmgrserver" -profile "$VMGR_PROFILE" -status_basic 2>&1 | tail -1
echo "Address:  $VMGR_FQDN:$VMGR_PORT"
rm -f cds.lib
