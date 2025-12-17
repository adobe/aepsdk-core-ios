# AGENTS.md

## 1. Build & Test

- **Build**: `make build`
- **Test (All)**: `make test`
- **Test (Module)**: `make test-core`, `make test-services`, `make test-identity`, etc.
- **Lint**: `make lint`

## 2. Project Structure

- **AEPCore**: Core logic (EventHub, Rules Engine, etc.).
- **AEPServices**: Low-level services (Network, Disk, etc.) and shared Utilities.
- **AEPIdentity**: Identity extension.
- **AEPLifecycle**: Lifecycle extension.
- **AEPSignal**: Signal extension.
- **AEPTestUtils**: Shared test utilities and mocks (aggregates tools from AEPCore and AEPServices for test targets).
    - Note: Published separately via GitHub tags (e.g., `testutils-5.6.0`). Not available on public package managers (CocoaPods trunk) as it is intended for internal/development use.

## 3. Testing Conventions

- **JSON Validation**: We use a fluent JSON assertion tool (`assertJSON`).
    - **Usage Guide**: `Documentation/Testing/JSONValidation.md` (Read this to learn how to write easily configurable assertions for JSON-like structures, such as Event data payloads, NetworkRequest payloads, and raw JSON strings).
    - **Source Code**: `AEPServices/Mocks/PublicTestUtils/JSONValidation/`.
    - **Maintenance Guide**: `AEPServices/Mocks/PublicTestUtils/JSONValidation/AGENTS.md` (Read this only if modifying the validation tool itself).

## 4. Git Workflow

- Branches: `feature/...` or `fix/...`
- Commits: Conventional Commits (e.g., `feat: add new API`, `fix: crash on launch`).

