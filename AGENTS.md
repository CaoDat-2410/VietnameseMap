# AGENTS.md

Project harness for reliable agent-assisted development on VN Map Campaign Module.

## Project Stack

- **Backend**: Java Spring Boot (Docker)
- **Database**: PostgreSQL (port 15432)
- **Cache**: Redis (port 6379)
- **Frontend**: Flutter Web

## Services

| Service | Port | Status |
|---------|------|--------|
| vnmap_backend | 8080 | Running (healthy) |
| vnmap_postgres | 15432 | Running (healthy) |
| vnmap_redis | 6379 | Running (healthy) |

## Startup Workflow

Before writing code:

1. **Confirm working directory** with `pwd`
2. **Read this file** completely
3. **Read project docs** (`UI_UX_AUDIT_REPORT.md`, docs if present)
4. **Run verification** - Flutter: `cd FE && flutter analyze`, Backend health check
5. **Read `feature_list.json`** to see current feature state
6. **Review recent commits** with `git log --oneline -5`

If baseline verification is failing, repair that first before adding new scope.

## Working Rules

- **One feature at a time**: Pick exactly one unfinished feature from `feature_list.json`
- **Small commits preferred**: Each commit should be reviewable in < 5 minutes
- **Verification required**: Don't claim done without running verification commands
- **Update artifacts**: Before ending session, update `progress.md` and `feature_list.json`
- **Stay in scope**: Don't modify files unrelated to the current feature
- **Leave clean state**: Next session must be able to run verification immediately
- **No backend rewrite**: Backend changes only when required for env config or API compatibility

## Required Artifacts

- `feature_list.json` - Feature state tracker (source of truth)
- `progress.md` - Session continuity log
- `session-handoff.md` - Optional, for larger sessions

## Definition of Done

A feature is done only when ALL of the following are true:

- [ ] Target behavior is implemented
- [ ] Required verification actually ran (flutter analyze / build / browser test)
- [ ] Evidence recorded in `feature_list.json` or `progress.md`
- [ ] Repository remains restartable from standard startup path

## End of Session

Before ending a session:

1. Update `progress.md` with current state
2. Update `feature_list.json` with new feature status
3. Record any unresolved risks or blockers
4. Commit with descriptive message once work is in safe state
5. Leave repo clean enough for next session to run verification immediately

## Verification Commands

```bash
# Flutter frontend verification
cd FE
flutter analyze
flutter build web --release

# Backend health check
curl http://localhost:8080/actuator/health
```

## Current Known Issues (from UI_UX_AUDIT_REPORT.md)

| Priority | Issue | Files |
|----------|-------|-------|
| High | Tab switching bug | `event_detail_page.dart`, `school_detail_page.dart` |
| Medium | Corrupted Vietnamese text | `weather_page.dart` |
| Medium | Hardcoded campaign create | `campaign_list_page.dart` |
| Medium | Missing archive UI | Events, Campaigns |
| Low | No page transitions | `router.dart` |
| Low | Raw date/time display | Event form |

## Escalation

If you encounter:
- **Architecture decisions**: Consult project docs if present, otherwise ask user
- **Unclear requirements**: Check UI_UX_AUDIT_REPORT.md, otherwise ask user
- **Repeated failures**: Update progress, flag for human review
- **Scope ambiguity**: Re-read `feature_list.json` for definition of done
