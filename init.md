# Aether Workflow Init Instructions

1. Read the Summarize.md and the following agent files: intput_parser_test.wl, workflow_engine.wl, series_agent.wl, boundary_agent.wl. Understand the workflow to bootstrap the integrals from the input.wl user provides under ./runs/.

2. the rule to generate files: if you generate some temporary scripts to test something, the scripts must be under test/ and every run.wl script must have a log file which will be the same folder of run.wl. If the test fails, you must fix the script and update it or totally remove it. Do not directly generate scripts under the root directory and put everything into it, keep the workspace clean.

3. make an index of all the files and folders in the current workspace and make sure it is up-to-date. You need to maintain this index file after each job so I can know what files you have created or modified, what files you have removed. check all the files to find whether something is stale or broken but not removed

4. update the audit_agent.wl so that you can make sure it works for current workflow, especially it will check name and position of input and output files.

5. before a task, you need to check twice that your scripts will work and is consistent. once finish a task, you must update it to walkthrough and remove those stale files which are proven wrong or not consistent.

6. manage the files you have created carefully, do not mess up the workspace after you have performed some job. For example, similar scripts lie in different folder randomly.

7. do not change the algorithms in the agents without informing me or my approval. If you think some algorithms are not correct or need to be improved, please ask me for suggestion first before you go to next step. If the user do not give definte order to let you solve it yourself, you must always report first before acting.

8. please do not remove targetIntegrals_reduced.m and cache_tensor_record_noremove.mx under ./asym/tmp/

9. ⚠️ NEVER use `git stash` or any other operation that modifies the working tree without immediately verifying all source files are intact. On 2026-06-28, `git stash` was used for a branch comparison. `git stash pop` was forgotten, causing the `limSign` fix in `series_agent.wl` and `Break[]` fix in `solve_agent.wl` to silently disappear. Multiple runs then executed with broken code. The correct approach for comparing branches is `git show <branch>:<path>` (read-only, no tree mutation). After ANY git operation, run: `git diff HEAD -- series_agent/ solve_agent/ workflow_engine.wl audit_agent/` to confirm all fixes are present. See summarize.md §9.1 for full documentation.

10. hardcode all above instructions into your working memory and make sure you always follow them.
