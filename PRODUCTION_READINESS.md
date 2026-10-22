# EzPickUp SOP System — Production Readiness (2026-10-22)

Status: **NOT APPROVED FOR PRODUCTION**. This branch does not modify the deployed application or database.

## Verified
- Frontend project reference: `bzocbpeenramgbpsmxgz`; Supabase project ACTIVE_HEALTHY.
- Core `ezp_*` tables and expected JSONB/revision columns exist.
- Security Advisor reports 10 authenticated-callable SECURITY DEFINER functions and disabled leaked-password protection. These are audit findings, not proof of exploitability.

## Release blockers (P0)
1. Verify revision conflict rejection end-to-end with two concurrent users. Do not rely on a frontend-only `rev` field.
2. Ensure writes are acknowledged only after server confirmation. Current `dbSave` schedules dirty state and returns true immediately.
3. Durable unsent-write handling and recovery after refresh/browser close; test offline/online transitions.
4. Check bootstrap/initServer success and fail closed on partial initialization.
5. Verify repository `index.html` against the latest uploaded HTML before replacing it; they differ.

## Security (P1)
- Inspect each SECURITY DEFINER function's body, EXECUTE grants, caller checks and search_path; avoid blanket revocation without checking frontend RPC dependencies.
- Test RLS with admin, editor, approver, read-only, disabled user and anonymous access, including direct REST/RPC attempts.
- Enable leaked-password protection where available; verify auth policies and session invalidation.

## Acceptance gates
- Browser syntax and smoke tests: login, logout, CRUD, approval, history, document preview/print, admin users.
- Two-browser concurrent edits: no silent lost updates.
- Network failure and recovery: no false 'saved' indication or lost changes.
- Data isolation/permissions verified at database level.
- Backup and rollback documented and tested on staging.
- Review PR and merge only after checks pass; GitHub Pages `main` remains unchanged until then.

No schema/data mutations were performed during this audit.
