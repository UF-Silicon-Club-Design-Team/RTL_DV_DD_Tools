#!/usr/bin/env bash
# setup.sh -- create your own Verisium Manager (vManager) server, once.
#
#   ./setup.sh <ece-lnx number> [server-dir]     e.g.  ./setup.sh 05
#                                                (server-dir default: ~/vmgr_server)
#
# The server runs on ece-lnx-<number>. Creates a PostgreSQL database and a
# Verisium Manager server profile under server-dir, picks two free ports,
# generates passwords, installs the start/stop/status/connect scripts there
# and starts the server. Run from any ece-lnx host: if it isn't the chosen
# one, the script re-runs itself there over ssh (home directories are shared).
set -euo pipefail
NUM=${1:-}
[[ $NUM =~ ^[0-9]+$ ]] || { echo "usage: $0 <ece-lnx number> [server-dir]    e.g. $0 05"; exit 2; }
NUM=$(printf '%02d' "$((10#$NUM))")
TARGET=ece-lnx-$NUM
DOMAIN=${VMGR_DOMAIN:-ad.ufl.edu}   # full machine name: ece-lnx-NN.<domain>
KIT=$(cd "$(dirname "$0")" && pwd)
DIR=$(realpath -m "${2:-$HOME/vmgr_server}")
if [[ $(hostname -s) != "$TARGET" ]]; then
  echo "== Running setup on $TARGET (ssh)"
  exec ssh -t "$TARGET.$DOMAIN" "$KIT/setup.sh" "$NUM" "$DIR"
fi
VERISIUM=${VERISIUM_HOME_OVERRIDE:-/apps/cds/verisium2409}
XCELIUM=${XCELIUM_HOME_OVERRIDE:-/apps/cds/xcelium2409}
ADMIN=$VERISIUM/tools/vmgr/admin
HOST=$(hostname -s)

[[ -x $ADMIN/vmgrserver ]] || { echo "Verisium Manager not found at $VERISIUM"; exit 1; }
[[ -d $XCELIUM ]] || { echo "Xcelium not found at $XCELIUM"; exit 1; }
if [[ -e $DIR/config.sh ]]; then echo "$DIR is already set up (found config.sh). Use $DIR/start.sh"; exit 1; fi
mkdir -p "$DIR"; chmod 700 "$DIR"

# Two free consecutive ports (database, server)
port_free() { ! ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$1\$"; }
for _ in $(seq 200); do
  P=$(( 20000 + RANDOM % 20000 ))
  port_free "$P" && port_free $((P + 1)) && break
done
DB_PORT=$P; SRV_PORT=$((P + 1))

# Passwords: letters and digits, starting with a letter (Verisium Manager's rule)
pw() { echo "p$(head -c 300 /dev/urandom | tr -dc 'A-Za-z0-9' | cut -c1-15)"; }

umask 077
cat > "$DIR/config.sh" <<CFG
# Your Verisium Manager server. Private: keep chmod 600.
VMGR_ADMIN=$ADMIN
VMGR_HOST=$HOST
VMGR_FQDN=$(hostname -f)
VMGR_DB_DIR=$DIR/db
VMGR_PROFILE=$DIR/profile
VMGR_DB_PORT=$DB_PORT
VMGR_PORT=$SRV_PORT
VMGR_DB_SYS_PASSWORD=$(pw)
VMGR_DB_USER=vmgruser
VMGR_DB_PASSWORD=$(pw)
VMGR_DB_NAME=vmgrdb
CFG
cp "$KIT"/start.sh "$KIT"/stop.sh "$KIT"/status.sh "$KIT"/connect.sh "$DIR"/
chmod 700 "$DIR"/*.sh
source "$DIR/config.sh"

set +eu; source /apps/settings >/dev/null 2>&1; set -eu
cd "$DIR"
echo "== Creating the database (port $DB_PORT) in $DIR/db"
"$ADMIN/vmgrcreatedb" -db_dir "$VMGR_DB_DIR" -db_port "$VMGR_DB_PORT" -sys_password "$VMGR_DB_SYS_PASSWORD"
"$ADMIN/vmgrdb" -start -db_dir "$VMGR_DB_DIR"
echo "== Creating the server profile (host $HOST, port $SRV_PORT, simulator $XCELIUM)"
"$ADMIN/vmgrprofile" -create -profile "$VMGR_PROFILE" \
  -db_host "$HOST" -db_port "$VMGR_DB_PORT" -db_sys_password "$VMGR_DB_SYS_PASSWORD" \
  -db_user "$VMGR_DB_USER" -db_password "$VMGR_DB_PASSWORD" -db_name "$VMGR_DB_NAME" \
  -host "$HOST" -port "$VMGR_PORT" -memory 2048m -xlm_home "$XCELIUM" | grep -v '^ -'
rm -f cds.lib
echo "== Starting the server"
"$DIR/start.sh"
echo
echo "Done. Your server: $(hostname -f):$SRV_PORT   (scripts in $DIR)"
echo "Open it:  $DIR/connect.sh          (GUI; needs ssh -Y or a remote desktop)"
