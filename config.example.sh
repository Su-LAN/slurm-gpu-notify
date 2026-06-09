#!/usr/bin/env bash
# slurm-gpu-notify — configuration template.
#
# Copy this file to `config.local.sh` and fill in YOUR values:
#     cp config.example.sh config.local.sh
#     $EDITOR config.local.sh
#
# config.local.sh is git-ignored, so your account/email never get committed.

# ──────────────────────────── Connection ────────────────────────────────────
# SSH target for the cluster LOGIN node. Easiest: define a passwordless,
# key-based alias in ~/.ssh/config and put the alias here.
#
# Example ~/.ssh/config entry:
#   Host mycluster
#     HostName login.hpc.example.edu
#     User myaccount
#     IdentityFile ~/.ssh/mycluster_ed25519
#     IdentitiesOnly yes
#
# Then test:  ssh mycluster 'hostname'   (must work WITHOUT a password prompt)
SGN_SSH="mycluster"                 # ssh alias OR user@host

# Where notification e-mails go. Must be deliverable from the cluster's mail
# system — an institutional address on the same domain is the most reliable.
SGN_EMAIL="you@example.edu"

# ───────────────────────── Slurm / cluster specifics ────────────────────────
# Directory holding the slurm binaries (sbatch/srun/squeue/scontrol) IF they are
# not already on PATH in a plain (non-login) ssh shell. Leave "" if they are.
# Find it with:   ssh mycluster 'bash -lc "command -v sbatch"'
SGN_SLURM_BIN="/sw/slurm/23.11.6/bin"   # or "" if already on PATH

SGN_PARTITION="LocalQ"             # Slurm partition (run `sinfo` to list)
SGN_RESERVATION=""                 # optional reservation name, e.g. "alan100"; "" = none
SGN_QOS=""                         # optional QOS, e.g. "alan"; "" = none

# Default resource request for `sgn-request` (override per call with flags).
SGN_GRES="gpu:a100:1"              # e.g. full card gpu:a100:1, or a MIG slice gpu:a100_1g.20gb:1
SGN_CPUS="8"
SGN_MEM="64G"
SGN_TIME="1-00:00:00"              # walltime, format D-HH:MM:SS (here: 1 day)

# ─────────────────── GPU utilisation in the hourly report ───────────────────
# How to read per-job GPU utilisation:
#   login_idx : run `nvidia-smi --id=<IDX>` ON the login node, using the GPU
#               index Slurm reports in `scontrol show job -d` (IDX:). Exact and
#               cheap when the login node IS the compute node (single-node DGX)
#               or otherwise sees the job's GPU. RECOMMENDED for such clusters.
#   srun      : run nvidia-smi inside the job via `srun --overlap`. Works on
#               multi-node clusters; exact when the site enforces cgroup device
#               isolation, a bit noisy (lists all visible GPUs) otherwise.
#   none      : skip GPU utilisation; report job state + ETA only.
SGN_GPU_STAT_VIA="login_idx"
SGN_LOGIN_NODE="dgxlogin"          # informational; the node nvidia-smi runs on

# Cron schedule for the hourly report (standard 5-field crontab spec).
SGN_REPORT_CRON="0 * * * *"        # top of every hour

# When you have NO jobs (nothing running or pending): 0 = stay silent (no email),
# 1 = still send a "no jobs" heartbeat so you know the monitor is alive.
SGN_EMAIL_WHEN_EMPTY="0"
