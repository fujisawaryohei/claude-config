<!-- MIT License - Copyright (c) 2026 Affaan Mustafa - https://github.com/affaan-m/everything-claude-code -->
---
description: Sequential and tmux/worktree orchestration guidance for multi-agent workflows.
---

# Orchestrate Command

Sequential agent workflow for complex tasks.

## Usage

`/orchestrate [workflow-type] [task-description]`

## Workflow Types

### feature
Full feature implementation workflow:
```
planner -> tdd-guide -> code-reviewer -> security-reviewer
```

### bugfix
Bug investigation and fix workflow:
```
planner -> tdd-guide -> code-reviewer
```

### refactor
Safe refactoring workflow:
```
architect -> code-reviewer -> tdd-guide
```

### security
Security-focused review:
```
security-reviewer -> code-reviewer -> architect
```

## Execution Pattern

For each agent in the workflow:

1. **Invoke agent** with context from previous agent
2. **Collect output** as structured handoff document
3. **Pass to next agent** in chain
4. **Aggregate results** into final report

## Handoff Document Format

Between agents, create handoff document:

```markdown
## HANDOFF: [previous-agent] -> [next-agent]

### Context
[Summary of what was done]

### Findings
[Key discoveries or decisions]

### Files Modified
[List of files touched]

### Open Questions
[Unresolved items for next agent]

### Recommendations
[Suggested next steps]
```

## Final Report Format

```
ORCHESTRATION REPORT
====================
Workflow: feature
Task: [task description]
Agents: planner -> tdd-guide -> code-reviewer -> security-reviewer

SUMMARY
-------
[One paragraph summary]

FILES CHANGED
-------------
[List all files modified]

TEST RESULTS
------------
[Test pass/fail summary]

RECOMMENDATION
--------------
[SHIP / NEEDS WORK / BLOCKED]
```

## Parallel Execution

For independent checks, run agents in parallel:

```markdown
### Parallel Phase
Run simultaneously:
- code-reviewer (quality)
- security-reviewer (security)
- architect (design)

### Merge Results
Combine outputs into single report
```

## External Worktree Orchestration

For long-running or cross-harness sessions with isolated git worktrees:

```bash
node scripts/orchestrate-worktrees.js plan.json --execute
```

Use `seedPaths` in the plan file to overlay local files into worker worktrees:

```json
{
  "sessionName": "workflow-e2e",
  "seedPaths": ["scripts/orchestrate-worktrees.js"],
  "workers": [
    { "name": "docs", "task": "Update orchestration docs." }
  ]
}
```

## Arguments

$ARGUMENTS:
- `feature <description>` - Full feature workflow
- `bugfix <description>` - Bug fix workflow
- `refactor <description>` - Refactoring workflow
- `security <description>` - Security review workflow
- `custom <agents> <description>` - Custom agent sequence
