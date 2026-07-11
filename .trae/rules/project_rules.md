# Project Rules

## Mathematica Process Management

**CRITICAL**: NEVER kill or terminate Mathematica/WolframKernel processes with a blanket `kill -9` command that targets ALL processes (e.g., `ps aux | grep MathKernel | awk '{print $2}' | xargs kill -9`). The user may have their own Mathematica notebooks or kernels running independently.

When you need to clean up processes:
1. Always save the PID of any process you launch (e.g., `MY_PID=$!`)
2. Only kill specific PIDs that you launched yourself
3. Use `cat /tmp/trae_mirror_pid.txt` to retrieve the PID of your background job if needed

Example safe cleanup:
```bash
# Save PIDs when launching
MY_PID=$!
echo "my_pid=$MY_PID" > /tmp/trae_mirror_pid.txt

# Kill only your own processes later
kill -9 $(cat /tmp/trae_mirror_pid.txt) 2>/dev/null
# Also kill subkernels spawned by your job (they will be children of your PID)
pkill -P $(cat /tmp/trae_mirror_pid.txt) 2>/dev/null
```

## Testing Commands

- Run mirror workflow: `MathKernel -noprompt -script test/mirror_full_run.wl`
- Check mirror log: `tail -f test/mirror_full_run.log`
- Check mirror output: `ls -lt series_agent/fourloopI173_svlist_mirror*`
