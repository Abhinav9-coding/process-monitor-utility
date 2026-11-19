#!/bin/bash
#
# Course        : Processor Architecture & Operating Systems Lab
# Script Title  : Process Monitor Utility (procmon.sh)
# Author        : [Your Name]
# Description   : Displays running processes with PID, CPU usage and
#                 memory usage using standard Linux commands.
# Usage         : ./procmon.sh [-n count] [-s cpu|mem|pid] [-u username] [-h]

# ---------- 1. DEFAULT VALUES ----------
TOP_N=10          # how many processes to display
SORT_BY="cpu"     # sorting criterion
FILTER_USER=""    # empty = show all users

# ---------- 2. FUNCTIONS ----------
usage() {
    echo "Usage: $0 [-n count] [-s cpu|mem|pid] [-u username] [-h]"
    echo "  -n count     Number of processes to display (default 10)"
    echo "  -s key       Sort by cpu, mem or pid (default cpu)"
    echo "  -u username  Show only processes of this user"
    echo "  -h           Show this help message"
}

error_exit() {
    echo "[ERROR]: $1" >&2
    echo "Program terminated with status code 1." >&2
    exit 1
}

# ---------- 3. COMMAND-LINE ARGUMENT PARSING ----------
while getopts ":n:s:u:h" opt; do
    case $opt in
        n) TOP_N=$OPTARG ;;
        s) SORT_BY=$OPTARG ;;
        u) FILTER_USER=$OPTARG ;;
        h) usage; exit 0 ;;
        \?) error_exit "Invalid option: -$OPTARG" ;;
        :)  error_exit "Option -$OPTARG requires an argument." ;;
    esac
done

# ---------- 4. VALIDATION ----------
# 4a. Required commands must exist
for cmd in ps awk free uptime; do
    command -v "$cmd" >/dev/null 2>&1 || error_exit "Required command '$cmd' not found."
done

# 4b. Count must be a positive integer
[[ "$TOP_N" =~ ^[1-9][0-9]*$ ]] || error_exit "Invalid process count. Value must be a positive integer."

# 4c. Sort key must be valid; map it to a ps sort key
case "$SORT_BY" in
    cpu) KEY="-pcpu" ;;
    mem) KEY="-pmem" ;;
    pid) KEY="pid"   ;;
    *)   error_exit "Invalid sort key '$SORT_BY'. Use cpu, mem or pid." ;;
esac

# 4d. If a user was given, it must exist on the system
if [ -n "$FILTER_USER" ]; then
    id "$FILTER_USER" >/dev/null 2>&1 || error_exit "User '$FILTER_USER' does not exist."
fi

# ---------- 5. SYSTEM SUMMARY ----------
echo "=================================================================="
echo "                 PROCESS MONITOR UTILITY"
echo "=================================================================="
echo "Host      : $(hostname)"
echo "Date/Time : $(date '+%Y-%m-%d %H:%M:%S')"
echo "Uptime    : $(uptime -p)"
echo "CPU Cores : $(nproc)"
echo "Load Avg  : $(awk '{printf "%s (1m), %s (5m), %s (15m)", $1, $2, $3}' /proc/loadavg)"
free -m | awk '/^Mem:/ {printf "Memory    : Total %d MB | Used %d MB | Free %d MB | Used %.1f%%\n", $2, $3, $4, ($3*100)/$2}'
echo "------------------------------------------------------------------"

# ---------- 6. COLLECT PROCESS DATA ----------
# Fields: PID, USER, STATE, %CPU, %MEM, RSS(KB), COMMAND
if [ -n "$FILTER_USER" ]; then
    PS_OUT=$(ps -u "$FILTER_USER" -o pid,user:12,stat,pcpu,pmem,rss,comm --no-headers --sort="$KEY")
else
    PS_OUT=$(ps -e -o pid,user:12,stat,pcpu,pmem,rss,comm --no-headers --sort="$KEY")
fi

if [ -z "$PS_OUT" ]; then
    error_exit "No processes found for the given filter."
fi

# ---------- 7. DISPLAY PROCESS TABLE ----------
echo "$PS_OUT" | head -n "$TOP_N" | awk '
BEGIN {
    printf "%-8s %-12s %-6s %6s %6s %10s  %s\n", "PID", "USER", "STATE", "%CPU", "%MEM", "RSS(MB)", "COMMAND"
    print "------------------------------------------------------------------"
}
{
    cmd = ""
    for (i = 7; i <= NF; i++) cmd = cmd $i " "     # command name may contain spaces
    printf "%-8s %-12s %-6s %6.1f %6.1f %10.1f  %s\n", $1, $2, $3, $4, $5, $6/1024, cmd
}'
echo "------------------------------------------------------------------"

# ---------- 8. SUMMARY STATISTICS ----------
echo "$PS_OUT" | awk '
BEGIN {
    name["R"] = "Running";  name["S"] = "Sleeping"; name["D"] = "Disk-wait"
    name["Z"] = "Zombie";   name["T"] = "Stopped";  name["I"] = "Idle"
}
{
    total++
    cpu += $4
    mem += $5
    state = substr($3, 1, 1)       # first letter of STAT is the main state
    count[state]++
}
END {
    printf "Total processes found  : %d\n", total
    printf "Combined CPU usage     : %.1f%%\n", cpu
    printf "Combined MEM usage     : %.1f%%\n", mem
    printf "Process states         : "
    for (s in count) printf "%s=%d  ", (s in name ? name[s] : s), count[s]
    printf "\n"
}'
echo "=================================================================="

exit 0
