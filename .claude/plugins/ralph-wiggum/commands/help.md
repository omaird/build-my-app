---
description: Explain Ralph Wiggum technique and available commands
---

# Ralph Wiggum Loop

A multi-persona iterative improvement technique that systematically improves code quality by rotating through specialized review perspectives.

## How It Works

The loop cycles through 6 personas, each making ONE focused improvement per iteration:

| # | Persona | Focus |
|---|---------|-------|
| 0 | Code Reviewer | Bugs, security, edge cases, types |
| 1 | System Architect | Structure, dependencies, separation of concerns |
| 2 | Frontend Designer | UI/UX, accessibility, animations |
| 3 | QA Engineer | Tests, build, code quality |
| 4 | Project Manager | Requirements, documentation |
| 5 | Business Analyst | User perspective, UX friction |

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-wiggum:ralph-loop [target]` | Start or resume the loop |
| `/ralph-wiggum:cancel-ralph` | Stop the active loop |
| `/ralph-wiggum:help` | Show this help |

## Targets

| Target | Description | Key Files |
|--------|-------------|-----------|
| `home` | Home page (default) | HomeFeature, HomeView |
| `adkhar` | Daily Adkhar / habits | AdkharFeature, AdkharView, HabitViews |
| `journeys` | Journeys feature | JourneysFeature, JourneyDetailFeature |
| `library` | Dua library | LibraryFeature, LibraryView |
| `practice` | Practice feature | PracticeFeature, PracticeView |

## Examples

```bash
# Start improving home page (default)
/ralph-wiggum:ralph-loop

# Start improving Daily Adkhar
/ralph-wiggum:ralph-loop adkhar

# Start improving Journeys
/ralph-wiggum:ralph-loop journeys
```

## Configuration

- **Max iterations:** 12 (2 full cycles through all personas)
- **State file:** `.claude/ralph-wiggum-state.yml`

## Human Escalation

If an issue persists for 2+ iterations across different personas, the loop pauses and requests human guidance before continuing.

## Managing State

**Resume existing loop:**
```
/ralph-wiggum:ralph-loop
```

**Start fresh (clear previous state):**
1. Delete `.claude/ralph-wiggum-state.yml`
2. Run `/ralph-wiggum:ralph-loop [target]`

**Switch targets mid-loop:**
The loop will warn if you pass a different target than the saved state. You can confirm to reset or continue the existing target.
