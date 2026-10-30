#!/usr/bin/env bash
# Open the Verisium Manager client on your server, in the current directory.
#   connect.sh             GUI (needs ssh -Y / X forwarding, or a remote desktop)
#   connect.sh -batch      command line
#   connect.sh -exec f     run a Tcl command file and exit
source "$(dirname "$0")/config.sh"
set +u; source /apps/settings >/dev/null 2>&1
exec "$(cd "$VMGR_ADMIN/../../.." && pwd)/bin/vmanager" -server "$VMGR_FQDN:$VMGR_PORT" "$@"
