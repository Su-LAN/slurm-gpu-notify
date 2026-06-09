---
name: slurm-gpu-notify
description: Reserve a GPU on a remote Slurm/HPC cluster over SSH and set up automated hourly email status reports (job state, GPU utilisation, pending-job ETA). Use when the user wants to request/allocate/hold a GPU on a Slurm cluster, attach to a running job, check cluster job status, or set up email notifications about their cluster jobs. Cluster details come from a per-user config file, so it works for any account once configured.
---

# slurm-gpu-notify

Toolkit to **reserve GPUs on a Slurm cluster** and **get hourly email status reports** that run on the cluster itself (independent of the user's laptop). All cluster/account specifics live in `config.local.sh`; the scripts are generic.

## Before doing anything
1. Ensure a config exists. If `config.local.sh` is absent, tell the user to
   `cp config.example.sh config.local.sh` and fill it in (SSH alias, email, slurm
   path, partition, optional reservation/qos). The SSH target must already do
   **passwordless key-based** login (`ssh <alias> hostname` works with no prompt).
2. Run `bin/sgn-doctor` to verify SSH, slurm, mail, cron and nvidia-smi. Fix any
   red line before continuing.

## Commands (in `bin/`, all read `config.local.sh`)
- `sgn-doctor` — pre-flight connectivity/tooling check. Run first.
- `sgn-request [--gres g] [--time D-HH:MM:SS] [--cpus n] [--mem 64G] [--name N] [--cmd '…']`
  — submit a GPU job with BEGIN/END/FAIL email. Default = a *holding* job
  (allocates the GPU then `sleep infinity`) to attach to; `--cmd` runs a real
  workload. Prints the job id.
- `sgn-status` — print the current report (all the user's jobs; RUNNING → GPU
  util + remaining walltime; PENDING → estimated start) without sending email.
- `sgn-monitor-install` — deploy the report script to the cluster and schedule it
  hourly via crontab. Sends one verification email. This is the durable notifier.
- `sgn-monitor-uninstall` — remove the cron entry and report script.
- `sgn-attach <jobid>` — interactive shell inside a running job (sees only its GPU).
- `sgn-cancel <jobid>` — release a job.

## Typical flows
- "Get me a GPU for a day" → `sgn-request` (adjust `--gres`/`--time` if asked),
  report the job id, then `sgn-attach <id>` once it is RUNNING.
- "Notify me about my jobs" → `sgn-monitor-install`; confirm the verification
  email arrived. Reports then arrive hourly with no further action.
- "Is it ready / how long?" → `sgn-status`.

## Notes / gotchas
- **Email reliability:** delivery uses the cluster's `mail`. An institutional
  address on the cluster's own domain is far more reliable than external Gmail
  (which may be blocked or land in spam). Prefer that for `SGN_EMAIL`.
- **GPU utilisation method** (`SGN_GPU_STAT_VIA`): `login_idx` is exact when the
  login node sees the job's GPU (single-node DGX). On multi-node clusters use
  `srun`, or `none` to skip util. See `config.example.sh`.
- **No cron daemon?** Some sites disable user cron on login nodes. `sgn-doctor`
  flags this; fall back to Slurm's `scrontab` (see README).
- Do **not** leave idle holding jobs running — they waste the GPU and the user's
  fair-share. Remind the user to `sgn-cancel` when done.
- These scripts only ever submit/cancel the user's *own* jobs and email the
  address in their own config.
