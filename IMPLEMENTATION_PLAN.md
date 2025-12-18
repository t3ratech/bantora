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
- [x] Add a DB-backed country table (code, name, calling code, currency, default language, registration-enabled)
- [x] Replace manual country code input with a searchable dropdown populated from the DB
- [x] Selecting a country should:
  - [x] Show country indicator (flag) next to the phone input
  - [x] Set phone calling-code prefix and build E.164 phone number automatically
  - [x] Prepopulate preferred language (English only as default for registration screen)
  - [x] Prepopulate currency
- [x] Persist selected country + preferred language + currency to the backend
- [x] Add backend validation to reject unsupported/non-African countries via DB lookup (no config/properties allowlist)

## Multi-language
- [ ] Implement language selection and switching in the Flutter UI (persist selection)
- [ ] Ensure language can be selected during registration and prepopulated based on country
- [ ] Add/extend UI tests to cover language switching and capture screenshots for manual verification

## Theme (Light/Dark)
- [x] Add app-wide light + dark theme support with persistence (same approach as Question5)
- [x] Add theme toggle on Login/Register screens
- [x] Add theme option/toggle within the main platform UI

## UI Testability & UX Feedback
- [x] Add stable accessibility semantics labels (login/register, poll cards, idea cards, search, action buttons)
- [x] Display deterministic UI state that can be asserted (counts per column, visible status messages)

## Home Screen Behaviors
- [x] Implement search filtering (polls + ideas) with visible result state
- [x] Implement vote-from-card flow (authenticated) with confirmation message and disabled vote buttons
- [x] Implement idea submission flow (authenticated) with confirmation message
- [x] Implement idea upvote flow (authenticated) with confirmation message and UI count increment

## Ideas: Categories, Hashtags, and Hourly AI Poll Generation
- [x] Update idea model to require category + 1..N hashtags at creation (no AI processing at idea creation)
- [x] Add UI controls to select a category and add/remove hashtags when submitting an idea
- [x] Add backend endpoints to list/search categories and hashtags, and to filter polls/ideas by category and hashtag
- [ ] Implement hourly AI job that:
  - [ ] Finds the top 2 hashtags with the most unprocessed ideas
  - [ ] Builds a token/size-bounded prompt containing as many idea summaries as possible
  - [ ] Instructs the AI to deduplicate/merge similar ideas, reject infeasible/unclear ones, and return a reduced set of polls
  - [ ] Creates polls + poll options and links each poll back to the source idea IDs used
  - [ ] Marks ideas as processed so they are never picked up again
- [x] Poll details must display all source ideas the poll was generated from (including member, full idea text, timestamps, and vote/upvote counts)
- [x] Update home page to a tabbed layout: Polls tab (existing) + Ideas tab (new & popular columns) with filtering by category and hashtags
- [x] Add dedicated routes for poll detail and idea detail (each has its own shareable link)
- [x] Add share buttons for polls and ideas: Facebook, X, WhatsApp, Threads, Email

## Backend Support
- [x] Implement AuthController (register/login/refresh/logout) and JWT validation
- [x] Enforce endpoint security for write operations (votes, idea create, idea upvote)

## Testing
- [x] Rewrite UI tests to login first and assert authenticated-only behavior (no anonymous actions)
- [x] Keep screenshots for manual verification during workflow runs
- [ ] Align screenshot verification workflow with current screenshot output path (bantora-web/bantora_app/test-results)
- [ ] Migrate all UI tests to Patrol 4.0:
  - [ ] Move all Flutter `flutter_test`-based UI tests to Patrol 4.0
  - [ ] Move all Java UI tests to Patrol 4.0 (replace Java harness entirely)
  - [ ] Remove legacy Java UI test code, dependencies, and test runners after Patrol parity is reached
  - [ ] Remove legacy/non-Patrol test suites after Patrol migration (scope must be enforced consistently across repo)
  - [ ] Update `bantora-docker.sh` test entrypoints to run Patrol 4.0 as the single UI test mechanism
  - [ ] Update `.windsurf` workflows/rules to run Patrol 4.0 and reflect the new screenshot verification flow
  - [ ] Stabilize Patrol-based UI tests for idea submission and upvoting (fix flakiness and make polling deterministic)

## Documentation
- [x] Update ARCHITECTURE.md + README.md (remove incorrect snippets and align with current code)
- [ ] Update ARCHITECTURE.md + README.md to document credentials file pattern and registration country/language/currency behavior
- [ ] Update ARCHITECTURE.md + README.md + IMPLEMENTATION_PLAN.md to document Patrol 4.0 as the only UI testing approach (including how to run it via `bantora-docker.sh`)
