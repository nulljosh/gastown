# Contributing to NYC Survive

## Setup

NYC Survive lives in the `labs` repo, in the `nyc/` folder.

```bash
git clone https://github.com/nulljosh/nyc.git
cd nyc
xcodegen generate && open NYCSurvive.xcodeproj
```

`project.yml` is the source of the Xcode project. Run `xcodegen generate` after you change it.

## Run

- **Apple apps.** Pick the `NYCSurvive` scheme for Mac or `NYCSurvive-iOS` for iPhone and iPad, then run.
- **Web.** `cd web && python3 -m http.server 8000`, then open http://localhost:8000.
- **Headless.** `scripts/playthrough.sh 200` plays the game to a win with no window.

## Test

```bash
node --test
xcodebuild test -project NYCSurvive.xcodeproj -scheme NYCSurvive -destination 'platform=macOS' -only-testing:SimTests
```

CI runs both (`.github/workflows/nyc-test.yml`), plus a check that the file references in the README still exist.

## Rules

- Colonists act only on orders. Do not add auto-assignment, even as a default.
- Rendering stays in SpriteKit inside the game scene.
- Shared rules change on every platform. If you change Swift game logic, check the web port in `web/js/` too.
- The license is Apache 2.0. By contributing, you agree your changes are licensed the same way.

## Making a change

- Keep the diff scoped to what you're fixing or adding. No drive-by refactors.
- Match the existing code style in the file you're touching.
- Open a PR with a short description of the why, not just the what.

## Reporting a bug

Open a GitHub issue with steps to reproduce. The smaller the repro, the faster it gets fixed.

For security problems, email trommatic@icloud.com instead. See [SECURITY.md](SECURITY.md).
