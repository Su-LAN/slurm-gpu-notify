# slurm-gpu-notify

Reserve GPUs on a remote **Slurm / HPC cluster** over SSH, and get **hourly email
status reports** about your jobs — GPU utilisation, memory, remaining walltime,
and estimated start time for anything still queued.

The monitoring runs **on the cluster itself** (a tiny hourly cron job), so you get
notified whether or not your laptop is awake or online. Everything cluster- and
account-specific lives in one git-ignored config file, so you set it up once and
forget it. Works as a plain shell toolkit **and** as a [Claude Code](https://claude.com/claude-code) skill.

---

## What you get

| Command | Does |
|---|---|
| `sgn-doctor` | Pre-flight check: SSH, slurm tools, mail, cron, nvidia-smi |
| `sgn-request` | Submit a GPU job (default: a "holding" allocation you attach to) with BEGIN/END/FAIL email |
| `sgn-status` | Print the current report now (no email) |
| `sgn-monitor-install` | Deploy + schedule the **hourly email report** on the cluster |
| `sgn-monitor-uninstall` | Remove it |
| `sgn-attach <jobid>` | Interactive shell inside a running job (sees only its GPU) |
| `sgn-cancel <jobid>` | Release a job |

Example hourly email:

```
GPU status report for s5449518
Generated: 2026-06-09 12:00:01 AEST   Host: dgxlogin
================================================================

[1] Job 24507  "hold_a100_p2"  --  PENDING
  Pending reason: Priority
  Est. start: 2026-06-10T07:20:00
  Approx wait: ~19h 20m from now

[2] Job 24483  "hold_a100full"  --  RUNNING
  Node: dgxlogin    GPU alloc: gres/gpu:a100:1
  Runtime: 4:40:07 / 1-00:00:00  (used / limit)
  Remaining: 19h 19m until walltime ends
  GPU usage:
      GPU #3 NVIDIA A100-SXM4-80GB: util 92%, mem 74618/81920 MiB (91%)
```

---

## Setup (≈3 minutes)

### 1. Passwordless SSH to your cluster
Create a key and an alias in `~/.ssh/config` so `ssh mycluster hostname` works
with **no password prompt**:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/mycluster_ed25519        # if you don't have a key
ssh-copy-id -i ~/.ssh/mycluster_ed25519.pub myaccount@login.hpc.example.edu
```

```sshconfig
# ~/.ssh/config
Host mycluster
  HostName login.hpc.example.edu
  User myaccount
  IdentityFile ~/.ssh/mycluster_ed25519
  IdentitiesOnly yes
```

### 2. Clone and configure
```bash
git clone https://github.com/<you>/slurm-gpu-notify.git
cd slurm-gpu-notify
cp config.example.sh config.local.sh
$EDITOR config.local.sh          # set SGN_SSH, SGN_EMAIL, slurm path, partition…
export PATH="$PWD/bin:$PATH"      # optional: put the commands on your PATH
```

Key fields (full comments in `config.example.sh`):
- `SGN_SSH` — your ssh alias or `user@host`
- `SGN_EMAIL` — where reports go (prefer an address on the cluster's own domain)
- `SGN_SLURM_BIN` — path to `sbatch`/`squeue` if not on PATH (`ssh mycluster 'bash -lc "command -v sbatch"'`)
- `SGN_PARTITION`, and optionally `SGN_RESERVATION` / `SGN_QOS`
- `SGN_GRES` — what to request, e.g. `gpu:a100:1` or a MIG slice `gpu:a100_1g.20gb:1`
- `SGN_GPU_STAT_VIA` — `login_idx` (single-node DGX) · `srun` (multi-node) · `none`

### 3. Verify, request, monitor
```bash
sgn-doctor                # all green?
sgn-request               # grab a GPU (prints a job id; emails you on start/end)
sgn-status                # see status any time
sgn-monitor-install       # turn on hourly email reports
```

---

## How GPU utilisation is measured

`scontrol show job <id> -d` reports the GPU index Slurm assigned (`…(IDX:3)`); the
report queries exactly that GPU with `nvidia-smi --id=3`. On a single-node DGX
(login node *is* the compute node) this is exact and cheap. On multi-node clusters
set `SGN_GPU_STAT_VIA=srun` to read it from inside the job via `srun --overlap`.

## No user cron on the login node?

Some sites disable per-user cron. `sgn-doctor` will say `cron: NOT-RUNNING`. Use
Slurm's built-in `scrontab` instead — `scrontab -e` and add:

```
0 * * * * $HOME/sgn_gpu_report.sh
```

(`sgn-monitor-install` still uploads the script; you just schedule it via scrontab.)

## Etiquette

A "holding" job keeps a GPU allocated until its walltime or until you cancel it.
**Don't leave idle holding jobs running** — release with `sgn-cancel <id>` when
done. Request realistic `--time`; over-requesting hurts your fair-share and
backfill chances.

## Security

`config.local.sh` (your account/email) is git-ignored and never committed. The
scripts authenticate with your existing SSH key, only ever touch **your own**
Slurm jobs, and only email the address in your config. No passwords are stored.

## License

MIT — see [LICENSE](LICENSE).
