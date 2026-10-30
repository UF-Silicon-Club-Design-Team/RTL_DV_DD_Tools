# Your own Verisium Manager (vManager) server

Cadence Verisium Manager (formerly vManager) is where vPlans, regressions and
coverage tracking live. Since release 23.09 it only works connected to a
server: the standalone "local mode" was removed, and `vmanager` on its own just
asks for a server address. The server and the PostgreSQL database it needs
ship with the Cadence install, so you can run a personal server under your own
account. These scripts do all of it with one command.

Written for the UF ECE `ece-lnx-*` machines (Verisium Manager 25.02 from
`/apps/cds/verisium2409`, Xcelium 24.09 from `/apps/cds/xcelium2409`), reached
from Windows with **RealVNC Viewer** or **MobaXterm**.

**Quick version:** get a terminal on an ece-lnx machine (VNC or MobaXterm, below; campus or UF VPN),
then `./setup.sh <machine number>` once, and `~/vmgr_server/connect.sh` to open it.

## Before you start: get a terminal on an ece-lnx machine (Windows)

UF ECE's Linux machines (`ece-lnx-01`, `ece-lnx-02`, ...) are reachable **on campus or
through the UF VPN**, with your UFL (Gatorlink) username and password. From outside
the department network, a machine's full name is `ece-lnx-NN.ad.ufl.edu`.
(UF ECE's guide: "ECE Student Computing Access", UNIX Remote Access.)

### Option A: RealVNC (recommended: a full Linux desktop that stays open)

1. **Start a VNC desktop** (once; it keeps running until that machine reboots).
   In PowerShell (or MobaXterm/PuTTY), log in to the department's Linux gateway:
   ```
   ssh <gatorlink>@linux.ece.ufl.edu
   ```
   and on the Linux machine run:
   ```bash
   vncserver -geometry 1920x1080
   ```
   Choose a VNC password when asked. The output names your machine and desktop
   number, e.g. `ece-lnx-01:36` = machine **ece-lnx-01**, desktop **36**.
   Note both: the machine number (`01`) is also where you'll put your Verisium Manager server.
2. **Connect with RealVNC Viewer** to `ece-lnx-01.ad.ufl.edu:36` (your machine and desktop),
   with the VNC password.
3. **Open a terminal** on the Linux desktop (right-click on empty desktop space → terminal) and run:
   ```bash
   source /apps/settings
   ```

Windows opened from this terminal appear on the VNC desktop: nothing else to configure.

Lost your desktop? `vncserver -list` (on that machine) shows your sessions;
`vncserver -kill :36` ends one; `vncpasswd` changes the VNC password.

### Option B: MobaXterm (SSH with graphics, no desktop)

1. MobaXterm → **Session** → **SSH**.
2. **Remote host:** `linux.ece.ufl.edu` (the gateway picks a machine) or a specific
   machine, `ece-lnx-NN.ad.ufl.edu`; tick **Specify username**: your Gatorlink username.
3. **Advanced SSH settings:** make sure **X11-Forwarding** is ticked (the default).
4. **OK**, log in with your Gatorlink password. MobaXterm's X server (the "X" icon,
   top right) starts by itself.
5. Run `hostname` to see which machine you're on (e.g. `ece-lnx-05`), and
   `echo $DISPLAY`, which must print something like `localhost:10.0`. If it's empty,
   X11-Forwarding is off: right-click the session → Edit session, and tick it.

Windows opened from this session appear as normal Windows windows. Over the VPN
this can be slow; VNC (option A) is smoother for a GUI-heavy tool.

## Set up your server (once, about 2 minutes)

In that terminal:

```bash
git clone <this repo>
cd RTL_DV_DD_Tools/verisium_manager_server
./setup.sh 05                  # your ece-lnx number: 05 = ece-lnx-05
```

The number picks the machine your server runs on (`ece-lnx-<number>`). Simplest
is the machine you're logged in to (with VNC: the machine your VNC desktop is on,
e.g. `01` for `ece-lnx-01:36`). You can also run it from another ece-lnx
machine: it then connects to the chosen one with ssh (you may be asked for your
password) and sets up there.

`setup.sh`:
1. picks two free ports (database and server), so several people can run servers on one machine;
2. generates passwords (Verisium Manager requires them to start with a letter);
3. creates the PostgreSQL database and the server profile, with Xcelium as the
   project simulator so coverage analysis works;
4. puts `start.sh`, `stop.sh`, `status.sh`, `connect.sh` and `config.sh` in
   `~/vmgr_server/`, starts the server and prints its address.

A different folder: `./setup.sh 05 /some/dir`.

## Open Verisium Manager

From the VNC terminal or the MobaXterm session:

```bash
~/vmgr_server/status.sh            # server running? (if not: ~/vmgr_server/start.sh)
cd ~/my_project                    # the folder with your design / vPlan / vsif
~/vmgr_server/connect.sh           # the Verisium Manager window opens
```

The first start takes a little while. Other ways to use the client:
`~/vmgr_server/connect.sh -batch` (command line), `~/vmgr_server/connect.sh -exec file.tcl`
(run a Tcl command file and exit).

**If the window doesn't open:**
- `Can't connect to X11` / `cannot open display`: in MobaXterm, X11-Forwarding is off
  (see Option B, step 5). In VNC this doesn't happen; make sure you're typing in a
  terminal *inside* the VNC desktop.
- `Server is not running`: `~/vmgr_server/start.sh`.
- Slow or laggy window over MobaXterm off campus: use VNC instead (it sends a picture
  of the desktop, which is faster than forwarding every window over SSH).

## Start, stop, status

These work from any ece-lnx machine; they ssh to your server's machine by themselves.

```bash
~/vmgr_server/start.sh             # after a reboot of the machine, or after stop.sh
~/vmgr_server/status.sh            # running? which address and port?
~/vmgr_server/stop.sh              # stop it when you won't use it for a while
```

## Web portal (optional)

Verisium Manager also has a web page: `http://ece-lnx-NN.ad.ufl.edu:<port>/web/vmgr/index.html`
(NN and port from `status.sh`; campus or UF VPN).
- **Your Windows browser:** on campus or the VPN, that address may open directly.
- **VNC:** open Firefox on the Linux desktop and go to `http://ece-lnx-NN:<port>/web/vmgr/index.html`.
- **MobaXterm:** run `firefox &` in the session (it opens over X11), or use
  MobaXterm's **Tunneling** tool to forward `<port>` to `ece-lnx-NN.ad.ufl.edu:<port>` and
  open `http://localhost:<port>/web/vmgr/index.html` in your Windows browser.

## Good to know

- **Reboots:** like a VNC desktop, the server stops when its machine reboots and doesn't restart by itself. Run `start.sh` again; your data is kept.
- **Machine:** the server always runs on the machine chosen at setup; the scripts go there for you.
- **Moving to another machine:** `~/vmgr_server/stop.sh && rm -rf ~/vmgr_server`,
  then `./setup.sh <new number>` (starts with an empty database).
- **Passwords:** in `~/vmgr_server/config.sh`, readable only by you.
- **Disk:** the database grows with your regressions (`~/vmgr_server/db`).
- **Start-up warnings** about kernel network settings (`rmem_max`, `tcp_fin_timeout`, ...)
  are recommendations for large multi-user servers. They need root and are safe
  to ignore for one user.
- **Remove everything:** `~/vmgr_server/stop.sh && rm -rf ~/vmgr_server`.
- **Shared machines:** each server is a PostgreSQL database plus a Java process.
  Stop yours when you aren't using it for a while.

## Other machines or installs

The defaults are UF's paths. Elsewhere, point the scripts at your installs:

```bash
VERISIUM_HOME_OVERRIDE=/path/to/verisium XCELIUM_HOME_OVERRIDE=/path/to/xcelium ./setup.sh <number>
```

Machine names are built as `ece-lnx-<number>.ad.ufl.edu`. On another site, set
`VMGR_DOMAIN=<your domain>` and change `TARGET=` in `setup.sh` if the machines are
named differently. The scripts also source `/apps/settings` (UF's
environment script) and skip it silently where it doesn't exist.

## Files

| File | What it does |
| --- | --- |
| `setup.sh` | one-time setup |
| `start.sh` / `stop.sh` / `status.sh` | start, stop, check the database and server |
| `connect.sh` | open `vmanager` on your server (extra arguments are passed on) |
| `config.sh` | written by `setup.sh` into your server folder: host, ports, folders, passwords |

## What the scripts run

For reference, the Cadence admin commands underneath
(`<verisium>/tools/vmgr/admin/`):

```bash
vmgrcreatedb -db_dir <dir>/db -db_port <db-port> -sys_password <pw>        # create PostgreSQL
vmgrdb       -start|-stop|-status -db_dir <dir>/db                         # run it
vmgrprofile  -create -profile <dir>/profile -db_host <host> -db_port <db-port> \
             -db_sys_password <pw> -db_user vmgruser -db_password <pw2> -db_name vmgrdb \
             -host <host> -port <port> -memory 2048m -xlm_home <xcelium>   # server profile
vmgrserver   -profile <dir>/profile -start|-stop|-status_basic              # run the server
vmanager     -server <host>:<port>                                          # client
```

The interactive alternative is `<verisium>/tools/vmgr/admin/vmgrconf`. Cadence's
own guide is `<verisium>/doc/vManagerinstall/`.
