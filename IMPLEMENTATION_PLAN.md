# Implementation Plan

## Authentication & Access Control
- [x] Implement login + registration UI and backend endpoints
- [x] Enforce authentication for voting, upvoting, and idea submission (no anonymous access)
- [x] Remove anonymous vote/upvote flow and remove phone-number input from the vote/upvote UI
- [ ] Implement SMS verification flow (AuthController /api/v1/auth/verify + UI)

## Credentials & Sensitive Configuration
- [x] Load sensitive configuration from `~/.gcp/credentials_bantora` (same pattern as Smatech/Question5)
- [x] Ensure secrets are not stored in repo `.env` (JWT secret, Twilio credentials, Gemini API key, Redis password, DB password)
- [x] `bantora-docker.sh` must source `~/.gcp/credentials_bantora` before running Docker Compose and tests
- [x] Ensure application fails fast if required secrets are missing

## Registration: African Country + Language + Currency
- [ ] Replace manual country code input with an African-country dropdown (African countries only)
- [ ] Selecting a country should:
  - [ ] Show country flag next to the phone input
  - [ ] Set phone calling-code prefix and build E.164 phone number automatically
  - [ ] Prepopulate preferred language (English only as default for registration screen)
  - [ ] Prepopulate currency
- [ ] Persist selected country + preferred language (and currency if stored) to the backend
- [ ] Add backend validation to reject non-African countries

## Multi-language
- [ ] Implement language selection and switching in the Flutter UI (persist selection)
- [ ] Ensure language can be selected during registration and prepopulated based on country
- [ ] Add/extend UI tests to cover language switching and capture screenshots for manual verification

## Theme (Light/Dark)
- [x] Add app-wide light + dark theme support with persistence (same approach as Question5)
- [x] Add theme toggle on Login/Register screens
- [x] Add theme option/toggle within the main platform UI

## UI Testability & UX Feedback
- [x] Add stable accessibility semantics labels for Playwright (login/register, poll cards, idea cards, search, action buttons)
- [x] Display deterministic UI state that can be asserted (counts per column, visible status messages)

## Home Screen Behaviors
- [x] Implement search filtering (polls + ideas) with visible result state
- [x] Implement vote-from-card flow (authenticated) with confirmation message and disabled vote buttons
- [x] Implement idea submission flow (authenticated) with confirmation message
- [x] Implement idea upvote flow (authenticated) with confirmation message and UI count increment

## Backend Support
- [x] Implement AuthController (register/login/refresh/logout) and JWT validation
- [x] Enforce endpoint security for write operations (votes, idea create, idea upvote)

## Testing
- [x] Rewrite Playwright UI tests to login first and assert authenticated-only behavior (no anonymous actions)
- [x] Keep screenshots for manual verification during workflow runs
- [ ] Align screenshot verification workflow with current screenshot output path (bantora-web/test-results/screenshots)

## Documentation
- [x] Update ARCHITECTURE.md + README.md (remove incorrect snippets and align with current code)
- [ ] Update ARCHITECTURE.md + README.md to document credentials file pattern and registration country/language/currency behavior
