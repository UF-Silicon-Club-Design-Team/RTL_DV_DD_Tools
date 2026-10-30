#!/usr/bin/env bash
# Start your database and Verisium Manager server (on its host; works from any ece-lnx host).
set -euo pipefail
cd "$(dirname "$0")"; source ./config.sh
# The server lives on one host: from any other ece-lnx host, re-run there over ssh.
[[ $(hostname -s) == "$VMGR_HOST" ]] || exec ssh -t "$VMGR_FQDN" "$PWD/$(basename "$0")" "$@"
set +eu; source /apps/settings >/dev/null 2>&1; set -eu
"$VMGR_ADMIN/vmgrdb" -status -db_dir "$VMGR_DB_DIR" >/dev/null 2>&1 || "$VMGR_ADMIN/vmgrdb" -start -db_dir "$VMGR_DB_DIR"
# The server prints recommended kernel network settings (root only); they are not needed for one user.
"$VMGR_ADMIN/vmgrserver" -profile "$VMGR_PROFILE" -start 2>&1 \
  | grep -v -E "Network checkup|System limits check|Highly recommended|Diagnostics' page|=====|^\s*$" || true
"$VMGR_ADMIN/vmgrserver" -profile "$VMGR_PROFILE" -status_basic | tail -1
rm -f cds.lib
echo "Connect: $(pwd)/connect.sh   (or: vmanager -server $VMGR_FQDN:$VMGR_PORT)"
