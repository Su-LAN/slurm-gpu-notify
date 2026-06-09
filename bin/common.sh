#!/usr/bin/env bash
# Shared helpers — sourced by every sgn-* command. Not meant to run directly.
set -euo pipefail

SGN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---- load config -----------------------------------------------------------
if [ -n "${SGN_CONFIG:-}" ] && [ -f "$SGN_CONFIG" ]; then
  # shellcheck disable=SC1090
  . "$SGN_CONFIG"
elif [ -f "$SGN_ROOT/config.local.sh" ]; then
  # shellcheck disable=SC1091
  . "$SGN_ROOT/config.local.sh"
else
  echo "ERROR: no config found." >&2
  echo "  cp '$SGN_ROOT/config.example.sh' '$SGN_ROOT/config.local.sh' and edit it," >&2
  echo "  or point SGN_CONFIG=/path/to/config.sh at your own copy." >&2
  exit 1
fi

# ---- defaults / validation -------------------------------------------------
: "${SGN_SSH:?set SGN_SSH in your config}"
: "${SGN_EMAIL:?set SGN_EMAIL in your config}"
SGN_SLURM_BIN="${SGN_SLURM_BIN:-}"
SGN_PARTITION="${SGN_PARTITION:-}"
SGN_RESERVATION="${SGN_RESERVATION:-}"
SGN_QOS="${SGN_QOS:-}"
SGN_GRES="${SGN_GRES:-gpu:1}"
SGN_CPUS="${SGN_CPUS:-8}"
SGN_MEM="${SGN_MEM:-64G}"
SGN_TIME="${SGN_TIME:-1-00:00:00}"
SGN_GPU_STAT_VIA="${SGN_GPU_STAT_VIA:-login_idx}"
SGN_REPORT_CRON="${SGN_REPORT_CRON:-0 * * * *}"

# Prefix that puts the slurm bins on PATH for a remote NON-login shell.
sgn_path_prefix() {
  [ -n "$SGN_SLURM_BIN" ] && printf 'export PATH=%s:$PATH; ' "$SGN_SLURM_BIN"
}

# Run one command string on the cluster (non-interactive, key-based auth).
remote() {
  ssh -o BatchMode=yes -o ConnectTimeout=20 "$SGN_SSH" "$(sgn_path_prefix)$1"
}

# Render the hourly-report script from the template, substituting config values.
# Emits the final script to stdout.
render_report() {
  local pathline=":"
  [ -n "$SGN_SLURM_BIN" ] && pathline="export PATH=$SGN_SLURM_BIN:\$PATH"
  sed -e "s|@EMAIL@|$SGN_EMAIL|g" \
      -e "s|@GPU_STAT_VIA@|$SGN_GPU_STAT_VIA|g" \
      -e "s|@SLURM_PATH_LINE@|$pathline|g" \
      "$SGN_ROOT/remote/gpu_report.sh.tmpl"
}
