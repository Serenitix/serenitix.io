#!/usr/bin/env bash
# Abstraction: the live AuthDiff demo for the SURE talk — four patches, one command each.
# Mechanism: for each case, show the source-level patch, the guard in the before graph (`duc-proto normalize`),
#            then the comparison (`duc-proto diff`), pausing for Enter between steps. Colors: teal = guard,
#            amber = newly unguarded. Runs offline against the recorded DUC v2 fixtures.
# Policy: shows only what the prototype does today (lift, normalize, diff, witness paths); no checker evaluation.
#         The C shown is the fixture's documented source; the tool runs on the LLVM IR next to it.
# Scope: in duc-v2/target/debug/duc-proto and duc-v2/tests/*.ll. Out: terminal output only (or demo/recorded/ with --record).
# Contract: default runs the two live cases (1 doc fetch, 2 heartbeat); `--all` runs four; `--case N` one; `--fast` no pauses; `--record` writes fallback text.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
DUC_ROOT="${DUC_ROOT:-$HERE/../../../../duc-v2}"
BIN="$DUC_ROOT/target/debug/duc-proto"
T="$DUC_ROOT/tests"
FAST=0; ONLY=""; RECORD=0
ALL=0
while [ $# -gt 0 ]; do case "$1" in --fast) FAST=1;; --case) ONLY="$2"; shift;; --all) ALL=1;; --record) RECORD=1; FAST=1; ALL=1;; esac; shift; done
if [ "$RECORD" = 1 ] || [ ! -t 1 ]; then B=""; DIM=""; TEAL=""; AMB=""; RED=""; GRN=""; R=""; else
  B=$'\e[1m'; DIM=$'\e[2m'; TEAL=$'\e[1;36m'; AMB=$'\e[1;33m'; RED=$'\e[31m'; GRN=$'\e[32m'; R=$'\e[0m'; fi
[ -x "$BIN" ] || { echo "duc-proto not found at $BIN (set DUC_ROOT)"; exit 1; }

pause() { [ "$FAST" = 1 ] && { echo; return; }; printf "\n${DIM}[enter]${R}"; read -r _; echo; }
title() { [ "$FAST" = 1 ] || clear; printf "${B}%s${R}\n${DIM}%s${R}\n\n" "$1" "$2"; }
patch() { while IFS= read -r l; do case "$l" in -*) printf "${RED}%s${R}\n" "$l";; +*) printf "${GRN}%s${R}\n" "$l";; *) printf "%s\n" "$l";; esac; done; }
cmd() { printf "${B}\$ %s${R}\n" "$*"; }
guard() { # show the before-graph line(s) for the sensitive use, guard highlighted
  cmd "duc-proto normalize $1.ll | grep '$2'"
  "$BIN" normalize "$T/$1.ll" | grep -E "$2" | sed -E "s/(@ %[A-Za-z_0-9]+)\$/${TEAL}\1${R}/"
}
diff_() {
  cmd "duc-proto diff $1.ll $2.ll"
  "$BIN" diff "$T/$1.ll" "$T/$2.ll" | sed -n '5,$p' | sed -E \
    -e "s/^( +\+ .*)\$/${AMB}\1${R}/" -e "s/--\[true\]-->/--${AMB}[true]${R}-->/g"
}
run_case() {
  case "$1" in
  1) title "1 · Document fetch: an ownership check is deleted" "fixture OW-03 · paper §2"
     patch <<'EOF'
-  if (!acl_check(user_id, doc_id)) {
-      return NULL;
-  }
   return db_fetch_doc(doc_id);
EOF
     pause; echo "${B}Before the patch: what governs the fetch?${R}"; guard broken_access_control_safe 'db_fetch_doc'
     pause; echo "${B}What can an input reach now, unguarded, that it couldn't before?${R}"; diff_ broken_access_control_safe broken_access_control ;;
  2) title "2 · Heartbeat: a length check is deleted" "fixture DC-03 · model of CVE-2014-0160 (the IR model performs the copy with write)"
     patch <<'EOF'
   uint16_t payload_len = my_ntohs(req);
-  if (req_len < 2 || (size_t)payload_len > req_len - 2)
-      return;
   memcpy(resp, req + 2, payload_len);
EOF
     pause; echo "${B}Before the patch: what governs the copy?${R}"; guard heartbleed_toy_safe 'call\(@write'
     pause; echo "${B}What can the request reach now, unguarded?${R}"; diff_ heartbleed_toy_safe heartbleed_toy ;;
  3) title "3 · Ping endpoint: hostname validation is deleted" "fixture OW-02 · command injection"
     patch <<'EOF'
-  int ok = validate_hostname(host);
-  if (!ok) return -1;
   const char *cmd = build_ping_cmd(host);
   return system(cmd);
EOF
     pause; echo "${B}Before the patch: what governs the shell command?${R}"; guard cmd_injection_safe 'build_ping_cmd|@system'
     pause; echo "${B}What can the hostname reach now, unguarded?${R}"; diff_ cmd_injection_safe cmd_injection ;;
  4) title "4 · Integer dispatch: the range check goes, and the integer becomes a pointer" "fixture DC-02 · paper §6.1"
     patch <<'EOF'
-  if (user_val < 0 || user_val > 255)
-      return -1;
-  return write(1, safe_buf, (size_t)user_val);
+  volatile int *dangerous_ptr = (volatile int *)(long)user_val;
+  int leaked = *dangerous_ptr;
+  return write(1, safe_buf, (size_t)user_val + leaked);
EOF
     pause; echo "${B}Before the patch: what governs the write?${R}"; guard before 'call\(@write'
     pause; echo "${B}What can the integer reach now, unguarded?${R}"; diff_ before after ;;
  esac
}
# default: the two cases shown live in the talk (document fetch, heartbeat); --all runs all four
if [ "$ALL" = 1 ]; then DEF="1 2 3 4"; else DEF="1 2"; fi
cases="${ONLY:-$DEF}"
if [ "$RECORD" = 1 ]; then mkdir -p "$HERE/recorded"; for c in $cases; do run_case "$c" > "$HERE/recorded/case$c.txt"; done; echo "recorded to $HERE/recorded"; exit 0; fi
for c in $cases; do run_case "$c"; pause; done
printf "${B}Same command, different patches: each report names the input, what it now reaches, and the path.${R}\n"
