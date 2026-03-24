<!-- MIT License - Copyright (c) 2026 Affaan Mustafa - https://github.com/affaan-m/everything-claude-code -->
# Loop Start Command

Start a managed autonomous loop pattern with safety defaults.

## Usage

`/loop-start [pattern] [--mode safe|fast]`

- `pattern`: `sequential`, `continuous-pr`, `rfc-dag`, `infinite`
- `--mode`:
  - `safe` (default): strict quality gates and checkpoints
  - `fast`: reduced gates for speed

## Flow

1. Confirm repository state and branch strategy.
2. Select loop pattern and model tier strategy.
3. Enable required hooks/profile for the chosen mode.
4. Create loop plan and write runbook under `.claude/plans/`.
5. Print commands to start and monitor the loop.

## Required Safety Checks

- Verify tests pass before first loop iteration.
- Ensure loop has explicit stop condition.

## Loop Patterns

| Pattern | Use Case |
|---------|----------|
| `sequential` | Process a task list one by one |
| `continuous-pr` | Continuously create and merge PRs |
| `rfc-dag` | DAG-based RFC pipeline with dependencies |
| `infinite` | Run until explicitly stopped |

## Escalation Conditions (auto-stop)

The `loop-operator` agent escalates and stops when:
- No progress across 2 consecutive checkpoints
- Same error repeats with identical stack traces
- Cost drift outside budget window
- Merge conflicts blocking queue advancement

## Arguments

$ARGUMENTS:
- `<pattern>` optional (`sequential|continuous-pr|rfc-dag|infinite`)
- `--mode safe|fast` optional
