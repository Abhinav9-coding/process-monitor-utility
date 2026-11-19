# Process Monitor Utility (Shell Script)

A Bash utility that displays running processes with their **PID**, **CPU usage** and **memory usage**, along with system uptime, load average and memory statistics. Built using only standard Linux commands (`ps`, `free`, `uptime`, `awk`, `head`).

**Course:** Processor Architecture & Operating Systems Lab
**Author:** Abhinav Gadre | **Division:** SY – A | **Roll No.:** 16

## Problem Statement
Create a shell-based utility that displays running processes, process IDs, CPU usage, and memory usage using standard Linux commands.

## Features
- Lists processes with PID, user, state, %CPU, %MEM, RSS (MB) and command name
- Sorts by CPU, memory or PID
- Filters processes by username
- Shows system summary: host, uptime, CPU cores, load average, RAM usage
- Shows summary statistics: total processes, combined CPU/MEM, count per process state
- Input validation with clear error messages and non-zero exit status

## Requirements
- Linux (Ubuntu 22.04 LTS / Fedora / WSL2)
- Bash shell
- `procps` utilities (`ps`, `free`, `uptime`) and GNU `awk` (pre-installed on most distributions)

If any are missing on Debian/Ubuntu: `sudo apt install procps gawk`

## How to Run

```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>

# 2. Give the script execute permission
chmod +x procmon.sh

# 3. Run it
./procmon.sh
```

## Usage

```
./procmon.sh [-n count] [-s cpu|mem|pid] [-u username] [-h]
```

| Option | Description | Default |
|--------|-------------|---------|
| `-n count` | Number of processes to display (positive integer) | 10 |
| `-s key` | Sort by `cpu`, `mem` or `pid` | cpu |
| `-u username` | Show only this user's processes | all users |
| `-h` | Show help | - |

### Examples
```bash
./procmon.sh                  # top 10 by CPU
./procmon.sh -n 5 -s mem      # top 5 by memory
./procmon.sh -s pid -n 8      # first 8 sorted by PID
./procmon.sh -u root -n 5     # only root's processes
watch -n 2 ./procmon.sh       # live refresh every 2 seconds
```

### Error handling examples
```bash
./procmon.sh -n -2            # [ERROR]: Invalid process count...
./procmon.sh -s xyz           # [ERROR]: Invalid sort key...
./procmon.sh -u nouser123     # [ERROR]: User does not exist
echo $?                       # prints 1 (failure exit status)
```

## Sample Output
```
==================================================================
                 PROCESS MONITOR UTILITY
==================================================================
Host      : <hostname>
Date/Time : <date and time>
Uptime    : up 2 hours, 5 minutes
CPU Cores : 4
Load Avg  : 0.35 (1m), 0.40 (5m), 0.38 (15m)
Memory    : Total 7900 MB | Used 3100 MB | Free 2500 MB | Used 39.2%
------------------------------------------------------------------
PID      USER         STATE    %CPU   %MEM    RSS(MB)  COMMAND
------------------------------------------------------------------
1        root         Ss        0.1    0.1        9.8  systemd
...
------------------------------------------------------------------
Total processes found  : 55
Combined CPU usage     : 0.8%
Combined MEM usage     : 0.8%
Process states         : Sleeping=25  Idle=29  Running=1
==================================================================
```
*(Replace with a real screenshot/output from your run.)*

## How It Works
1. Parses options with `getopts` and validates them (regex, `case`, `id`)
2. Prints system info using `uptime`, `nproc`, `/proc/loadavg` and `free`
3. Collects process data once with `ps -o pid,user,stat,pcpu,pmem,rss,comm`
4. Formats the table with AWK `printf`
5. Computes totals and per-state counts using an AWK associative array

## Limitation
`ps` reports **average CPU usage over the process's lifetime**, not instantaneous usage like `top`.

## References
- Silberschatz, Galvin & Gagne, *Operating System Concepts*, Wiley
- Linux man pages: `ps(1)`, `free(1)`, `awk(1)`, `uptime(1)`, `proc(5)`
