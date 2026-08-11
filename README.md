# FoodRush

Group food ordering: **Room → Decide → Order → Receipt → Split**.

Flutter + Clean Architecture + Cubit. Mock-first by default; switch to Supabase with `.env`.

## Run (mock mode)

```bash
flutter pub get
flutter run
```

`.env` defaults:

```
USE_MOCKS=true
SUPABASE_URL=
SUPABASE_ANON_KEY=
BRANCH_KEY=
INVITE_BASE_URL=foodrush://join
```

## Connect Supabase (live mode)

### 1. Create project
Create a project at [supabase.com](https://supabase.com).

### 2. Apply SQL migrations
In the Supabase SQL editor (or CLI), run in order:

1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_rls.sql`
3. `supabase/migrations/003_supabase_live_fixes.sql`

### 3. Auth settings
Dashboard → **Authentication** → **Providers**:

- Enable **Email**
- Enable **Anonymous** (required for Continue as Guest)

Optional: disable “Confirm email” while developing.

### 4. Storage
Dashboard → **Storage** → create private bucket named `receipts`.

Add a simple policy for authenticated uploads (path `{room_id}/...`), e.g. allow authenticated users to `insert`/`select` on `receipts`.

### 5. App `.env`

```
USE_MOCKS=false
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=your_anon_key
BRANCH_KEY=
INVITE_BASE_URL=foodrush://join
```

Copy from Project Settings → API (`URL` + `anon` `public` key). **Never** put the service role key in the app.

### 6. Deep links (invite)

Invite share links use room **code** and store `rooms.invite_url` in Supabase.

Default format: `foodrush://join/ABC123`

- Android: custom scheme + optional `https://foodrush.app/join/...` (needs Digital Asset Links for autoVerify)
- iOS: `CFBundleURLTypes` scheme `foodrush`
- App listens via `app_links`, resolves code → room id with `get_room_by_code`, then joins

Test on a device/emulator:

```bash
# Android
adb shell am start -a android.intent.action.VIEW -d "foodrush://join/YOURCODE"

# iOS Simulator
xcrun simctl openurl booted "foodrush://join/YOURCODE"
```

Override base with `INVITE_BASE_URL` (e.g. `https://foodrush.app/join`) when you host a real domain / universal links.

### 7. Run

```bash
flutter pub get
flutter run
```

If credentials are missing, the app falls back to mocks automatically.

## Architecture

```
lib/
  core/          # theme, DI, router, failures, RoomPhase, MockAppStore, Supabase bootstrap
  l10n/          # app_en.arb, app_ar.arb + generated AppLocalizations
  features/
    auth|onboarding|room|suggestions|voting|race|orders|receipt|cost_sharing|
    payment_summary|history|profile|settings|deep_link/
      presentation/   # Cubits + screens
      domain/         # entities, repository contracts, use cases
      data/           # mock + supabase repository implementations
```

Rules:

- Widgets → Cubits → Use cases → Repository contracts
- Domain has no Flutter/Supabase imports
- Cubits never call Supabase directly
- Room phase from repository is source of truth for navigation
- `USE_MOCKS=false` registers `*SupabaseRepository`; otherwise `*MockRepository`

## Localization (English / Arabic)

Strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`. After editing them run:

```
flutter gen-l10n
```

Use `context.l10n.someKey` in widgets (`core/localization/l10n_extension.dart`).

## Manual test path

1. Continue as Guest → Create Room
2. Copy room code → (second guest session / same device join with another guest after logout)
3. Host Start → add restaurants → Vote or Race
4. Order → Lock → Upload receipt (or Skip) → Confirm split → Mark paid

Winner of race/vote is chosen once in the repository; clients only animate/display that result.

## Android release (GitHub Actions + Fastlane)

Push a version tag to build a release APK and attach it to a GitHub Release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Or: Actions → **Android Release** → Run workflow.

Fastlane lane (from `android/`):

```bash
cd android
bundle install   # needs Ruby 3.x + Bundler 2.5 (not system macOS Ruby 2.6)
GITHUB_TOKEN=… GITHUB_REPOSITORY=owner/repo RELEASE_TAG=v1.0.0 \
  bundle exec fastlane android github_release
```

Optional repo secrets for the baked `.env`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `USE_MOCKS`, `INVITE_BASE_URL`, `BRANCH_KEY`.

