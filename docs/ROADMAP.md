# NYC Roadmap

> Priority tier 3 (2026-10-17): active feature work, this month. Order: live blockers, ship pushes, active features, portfolio, exploratory. See ~/Documents/Code/LOOP-HANDOFF.md.

## CLOSED 2026-09-09: Gather-fix build iOS 1.0.1 approved and live

The gather-fix build (commit `49b474a`, 2026-09-09) fixed a critical bug: colonists could never
actually gather resources (job flipped back to idle before ResourceSystem could harvest), so
materials/cash were hard-capped at the starting stock. Fixed in both Swift (`JobSystem.swift`)
and web (`web/js/systems.js`); web is already deployed live at nyc.jaybulb.com. iOS 1.0.1
with icon alpha removed (ITMS-90717) received App Store approval and is now live at
https://apps.apple.com/app/id6782618198. App Store link added to README, landing page, and wiki.

## CLOSED 2026-09-09: 4.3(a) Spam appeal succeeded, iOS 1.0.0 APPROVED

Appeal filed by hand in the Resolution Center the morning of 2026-09-09 (per Joshua, not scripted/logged). Apple's approval email for submission `ee6f14f3-6fa3-4ba1-86c4-61582749fd48` confirms: "Review of your submission has been completed. It is now eligible for distribution." App Version 1.0.0 for iOS, live at https://apps.apple.com/app/nyc-survive/id6782618198 within 24h of release. Was: iOS rejected 2026-08-26 under Guideline 4.3(a) Design: Spam (account-level pattern, five apps same day). See "4.3(a) status, verified 2026-08-27" below for the original rejection record.

**Important: the game has never been played through end to end.** No automated full-playthrough test exists (still a TODO below), and known-open issues at time of approval include a 10-15s NEW GAME hang with no loading feedback and "controls aren't obvious" as the top usability complaint. Playtest before announcing broadly.

## App Review rejection reason, READ FROM RESOLUTION CENTER 2026-08-12

**Guideline 5.6, Developer Code of Conduct, Review Suspended.** Not an app-specific
defect. Verbatim: *"the current submission does not meet the required quality standard for
distribution on the App Store... this app is not eligible for resubmission before August
18th, 2026. Replies and resubmissions before this date will not be reviewed."*

Apple's listed next steps before resubmitting: no placeholder/unfinished/unrefined content;
every screen reviewed and tested; stable across **all** supported devices (iPad included if
the app is offered there); and **detailed notes of the improvements made** in the App Review
Information → Notes field. Continued similar submissions are warned as grounds for removal
from the Developer Program.

This hit 4 apps at once on 2026-08-09: curvely, nyc, transcriptly, wiretext.

Source: `asc web review show --app 6782618198 --apple-id trommatic@icloud.com` (needs `asc-login`;
the public API only returns a generic "unresolved issues" wrapper). Submissions frozen
The freeze lifted 2026-08-18; submission is now gated only on the four in-flight review verdicts.

## ASC state VERIFIED 2026-08-12 (`asc versions list`)

**Both platforms are `REJECTED`**, iOS 1.0.0 and macOS 1.0. The section below records both
as WAITING_FOR_REVIEW after the 2026-08-04 submission; they were reviewed and rejected.
Reasons are Resolution-Center-only (needs `asc-login`).

Freeze lifted 2026-08-18 (Guideline 5.6 suspension expired). Submitted that day and now
WAITING_FOR_REVIEW: Curvely iOS 1.2.0, Wiretext iOS 1.1.0, Wordroot iOS 1.0, Healstack iOS 2.3.4.
**Held pending those four verdicts, never a batch:** Sparkjar iOS+Mac, BCGD iOS+Mac, Wordroot Mac,
Lexly Mac. All six are `asc validate` clean (0 errors, 0 blocking) with a VALID build attached, so
each is one `asc review submit` away. Do not submit until the in-flight verdicts land.

## 2026-08-04, BOTH PLATFORMS SUBMITTED

**iOS 1.0.0 → WAITING_FOR_REVIEW** (submission `9338674e-4786-4003-b90a-b66ac0b95381`, build **6** `fcac5768-0102-41bb-9a32-667479f660e7`).
**macOS 1.0 → WAITING_FOR_REVIEW** (submission `55ebe4b1-9748-437d-95f9-f28b9e472d67`).

The orphan iOS submission was reused rather than minting a new one, `items add` against it succeeded once the screenshot existed, confirming the submission itself was never bad.

### Shipped a new build (6), not just a screenshot

Capturing the iPad screenshot surfaced a real defect: **`showsFPS`/`showsNodeCount` were set unconditionally**, so the debug FPS/node counter rendered on top of gameplay for real users in the shipping build (5). Both `Sources/App/NYCSurviveApp.swift` and `Sources/AppiOS/NYCSurviveApp.swift` are now `#if DEBUG` gated. Build 6 was archived from Release and verified clean before capture.

Screenshot is real gameplay (colony grid, resource HUD, 5 colonists, minimap), captured from a **Release** sim build so it matches what ships, asset `e0bc7e8f-432f-4a44-8f08-822dfbac1a8a`, set `63384daa-adb9-4bc1-bae9-3bfb493afa1b`, 2064×2752.

Entitlements verified on the exported IPA, NYC does **not** have the ITMS-90886 defect that affects curvely/wiretext/inkpress:
```
application-identifier  QMM486NPYC.com.heyitsmejosh.nyc
beta-reports-active     true      ← TestFlight-eligible
get-task-allow          false
```

### Corrections to the earlier 2026-08-03 note (it was wrong)
**`asc review doctor` is NOT a reliable submission gate.** It reported `errors: 0, blocking: 0` on iOS while `asc review items add` immediately rejected the version with two hard blockers doctor never mentioned:
- `appDataUsages`: "You must have published answers to your app's data usages"
- `appScreenshots`: "A screenshot with type ipadPro129 is required but was not provided"

So the original root-`CLAUDE.md` claim of "3 ASC-web-UI-only items" was **right**, and the "stale, warnings only" verdict was wrong. Always try `review items add` to learn the real blockers, doctor's clean bill means nothing.

Two of those three are now fixed **via CLI, no dashboard needed** (also disproving "ASC-web-UI-only"):

**Deploy gotcha (older note, check first):** `web/.vercel` is a stale leftover. The domain used to be a CNAME to `nyc-bum.pages.dev`, **Cloudflare Pages, not Vercel**. `wrangler.toml` now routes `nyc.jaybulb.com` to `dist/` as a Worker, so confirm the live path before you use the command below. Deploying with `vercel --prod` succeeds and changes nothing live. Correct command:
```
cd web && npx wrangler pages deploy . --project-name nyc --commit-dirty=true
```
Cloudflare edge cache can serve the old page for a minute or two afterward; the `CLOUDFLARE_DNS_TOKEN` lacks cache-purge permission, so just wait it out.

Availability confirmed fine (175/175 territories, free price schedule), the "dashboard-only dead end" belief was a CLI paging bug (fetch territories with `--limit 200`).

## Phase 2: Factorio Game Mechanics (TODO)
- [ ] ItemType enum (ore, iron_plate, copper_ore, etc.)
- [ ] Recipe system (inputs → outputs, timeTicks)
- [ ] ProductionBuilding model (replace colonist jobs)
- [ ] Belt/logistics system (item transport)
- [ ] LogisticsSystem (replaces JobSystem)
- [ ] Update SaveManager for new game state

## Phase 3: Enemy Waves & Defense (TODO)
- [ ] Enemy spawning and pathfinding
- [ ] Turret buildings
- [ ] Wall/defense mechanics

## Phase 4: Polish & Optimization (TODO)
- [ ] Performance profiling (iOS battery, frame rate)
- [ ] Mobile UI polish (touch targets ≥44pt)
- [ ] Save/load with new mechanics

## 2026-07-14 dump
- [ ] Splash screen redesign, sans-serif font, new app name applied throughout launch
- [ ] Investigate slow startup/loading
- [ ] Landing page (value prop, features, screenshots, download links, responsive)

## From App Store.pdf (imported 2026-07-29)
- [ ] NYC Survive icon needs to be more accurate/themed, user now wants this improved (previously marked "fine, no action", that's stale).

## App Store submission freeze, LIFTED 2026-08-18
Freeze lifted 2026-08-18 (Guideline 5.6 suspension expired). Submitted that day and now
WAITING_FOR_REVIEW: Curvely iOS 1.2.0, Wiretext iOS 1.1.0, Wordroot iOS 1.0, Healstack iOS 2.3.4.
**Held pending those four verdicts, never a batch:** Sparkjar iOS+Mac, BCGD iOS+Mac, Wordroot Mac,
Lexly Mac. All six are `asc validate` clean (0 errors, 0 blocking) with a VALID build attached, so
each is one `asc review submit` away. Do not submit until the in-flight verdicts land.
- **CLOSED 2026-08-25** (resolved, the 5.6 hold expired and both platforms were resubmitted; iOS 1.0.0 is WAITING_FOR_REVIEW and macOS 1.0.0 is IN_REVIEW as of 2026-08-25). Was: (historical) iOS 1.0.0 + macOS 1.0 SUSPENDED under 5.6 (6782618198). Unlike the others this is a real app (35 Swift files / 3,615 lines) and was likely swept up in the account-level action. Keep it. Resubmit LAST, after the thin apps are withdrawn, with detailed App Review notes describing the improvements.

## 2026-08-10, App Review notes are EMPTY, and 5.6 requires them
> RESOLVED 2026-08-24: this was stale, notes already existed on both platforms. They have now been
> extended with an "Improvements in this build (build 7)" section naming light mode and the resource
> bar fix, as 5.6 requires. Detail IDs: iOS 9d5b49ba-…, macOS d7fd2481-….
Apple's 5.6 letter lists this as a required action before resubmitting: "Include detailed notes of
the improvements made to the app in the Notes field of the App Review Information section in App
Store Connect." NYC Survive's review-details `notes` field is currently empty (verified via
`asc review details-for-version`). Curvely and Nullfolio have notes; NYC Survive and Wiretext do not.

## From Apple Notes (imported 2026-08-11)
- [ ] Build a landing/marketing page (currently app only, no preview)

> Resume note (2026-08-11): a `wip: partial work from /work notes ingest` commit holds unfinished, unverified changes for the items above. Review `git show HEAD` before building on it, it was committed mid-flight, not reviewed, and is unpushed.

## Guideline 5.6 resubmission checklist, prepared 2026-08-12, DO NOT SUBMIT BEFORE 2026-08-18

Apple's 5.6 notice makes one thing mandatory that is easy to miss: **"Include detailed notes
of the improvements made to the app in the Notes field of the App Review Information section."**
A resubmission without those notes is a wasted attempt, and 5.6 warns that repeat submissions
with the same issues can mean removal from the Developer Program.

The notes must describe improvements that were **actually made**. Nothing has been written into
ASC yet on purpose, there is nothing truthful to claim until the work below is done.

Before resubmitting:

- [ ] Walk every screen and interaction once, on device. 5.6 is a quality judgement, not a
      spec violation, the reviewer decided the app felt unfinished.
- [ ] Test on **every** device family the app is offered on. If `TARGETED_DEVICE_FAMILY` is
      `"1,2"` the app must be genuinely good on iPad, not merely launchable. Narrowing to
      iPhone-only is a legitimate alternative to making iPad good.
- [ ] Confirm a non-empty "What's New" (`asc metadata push`).
- [ ] Only then submit. Review detail id for this version: `9d5b49ba-8c2d-41ef-8bcb-80e59e7dec18 (iOS) / d7fd2481-09c9-4a23-b5e3-83738f9a4199 (macOS)`.

### From Notes (2026-08-14)
- [ ] **Automated full-playthrough test.** A script that drives an actual game start to finish, so a
      regression in the game loop fails loudly. Strictly a test harness, the shipped game must never
      play itself (see [[project_nyc_no_autoplay]]; the directive engine was deleted 2026-07-02 and
      does not come back).

## 5.6 defect verification 2026-08-18

**Verdict: "Play Now does nothing" reproduced-and-already-fixed; app not resubmitted.**

- Commit `d71b944` ("Fix Play Now: serve the game at /app") closed it.
  `nyc.jaybulb.com` → 200, and the landing page's `Play now` link (`landing/index.html`
  lines 132/175, `href="/app"`) → 200 after redirect to `/app/`. Claim no longer holds.
- Not a WKWebView shell: `Sources/` is 3126 lines of native Swift, no WebKit import.
- ASC state unchanged and correct: iOS 1.0.0 and macOS 1.0 both REJECTED, **neither
  resubmitted**. Signing-cert blocker RESOLVED (verified 2026-08-19): `iPhone Distribution:
  Joshua Trommel (QMM486NPYC)` is a valid codesigning *identity* in the local Keychain (SHA1
  1E8B7533…, private key present, cert valid to 2027-07-03). Only remaining gate is the
  one-app-at-a-time rule, hold until Curvely/Wiretext/Wordroot/Healstack clear review.
- The old `nycsurvive` subdomain does not resolve, but no ASC record references it. Cosmetic.

## 2026-08-19, hold confirmed, NOT resubmitted

Checked before doing anything: both NYC versions are still `REJECTED`
(iOS 1.0.0 `f595fe11-22d1-4169-85c4-b82dc7788a36`, macOS 1.0 `4610ab68-6b42-4ae0-9ba5-0965a83781a5`).

**Did not submit, on purpose.** The four in-flight reviews this repo gates on have not returned
a verdict, all still `WAITING_FOR_REVIEW` as of today: Curvely iOS 1.2.0, Wiretext iOS 1.1.0,
Wordroot iOS 1.0, Healstack iOS 2.3.4. (Wordroot macOS 1.0 is `PREPARE_FOR_SUBMISSION`.) The
standing one-app-at-a-time rule holds, and 5.6 explicitly warns that repeat submissions with the
same issues risk removal from the Developer Program.

`asc web review show` could not be re-read: Apple's SRP signin endpoint returned **503** on both
`asc web review show` and `asc-login`. Server-side and transient, not a credential problem, and
no 2FA prompt was ever reached. The verbatim reason recorded 2026-08-12 (Guideline 5.6,
account-level, not an app-specific defect) is still the best information we have.

- **CLOSED 2026-08-25** (done, both were resubmitted; iOS WAITING_FOR_REVIEW, macOS IN_REVIEW, verified 2026-08-25). Was: Resubmit NYC iOS 1.0.0 + macOS 1.0 once the four in-flight verdicts land. Signing cert is
      NO LONGER a blocker (verified 2026-08-19, see note above, valid identity + private key).
      The 5.6 improvement notes are already written on both platforms, so once unblocked this is
      a build + `asc review submit` away. The tutorial fix above is a genuine, describable
      improvement to add to the notes at that time.

## Rejection reason, read 2026-08-19
Read from Resolution Center once Apple's SRP 503 cleared. Submission
`9338674e`, IOS 1.0.0, thread dated 2026-08-09:

> Guideline 5.6 - Developer Code of Conduct - Review Suspended
> ... the current submission does not meet the required quality standard for
> distribution ... this app is not eligible for resubmission before August 18th, 2026.

So it is the known 5.6 suspension, NOT a separate defect, no new work implied.
That hold date has now passed. Apple's stated next steps are already satisfied:
the 5.6 improvement notes are written on both platforms, and the app is genuine
native Swift (3126 lines, no WebKit). Resubmit is therefore build + submit,
gated only on the one-app-at-a-time rule while Curvely/Wiretext/Wordroot/Healstack
are still WAITING_FOR_REVIEW.

## Braindump 2026-08-19
- [ ] Focus the week on the game itself. It's been worked on for months and is still unplayable: buttons don't really work, it's unusable, or controls aren't obvious once you start.
- [ ] Build a full test suite verifying a game can actually be played end to end, rules, resume, tutorial. The game must NOT play itself (see nyc no-autoplay rule); the suite is for verification only.

## Ingested 2026-08-22
- **CLOSED 2026-08-25** (done, resubmitted after the hold expired; both platforms are in the review queue as of 2026-08-25). Was: **App Store 5.6 suspension, now eligible to resubmit.** Apple held NYC Survive under Guideline 5.6 Developer Code of Conduct, "not eligible for resubmission before August 18th, 2026" (that date has passed as of 2026-08-22). Both iOS 1.0.0 and macOS 1.0 sit at UNRESOLVED_ISSUES / REJECTED. Before resubmitting Apple requires: every screen/interaction/piece of content thoughtfully designed and tested; no placeholder, unfinished, or unrefined content; stable and consistent across all supported devices; **and detailed notes of the improvements made, in the App Review Information Notes field.** Do a real quality pass first, a bare resubmit will be rejected again and repeat 5.6 violations escalate.

## 2026-08-23, eligible again, but needs a quality pass not a resubmit
Both iOS 1.0.0 and macOS 1.0 still read Rejected. The 5.6 suspension freeze expired 2026-08-18,
so resubmission is allowed. Apple asked for: no placeholder/unfinished/unrefined content, every
screen reviewed and tested, stability across all supported devices (iPad included), and detailed
improvement notes in App Review Information -> Notes.
- [ ] Do the actual quality pass before touching the submit button.
- [ ] Write the improvement notes into App Review Information.

## From /work start (imported 2026-08-24)
- [ ] macOS marketing version drifted from ASC: `project.yml` carries one `MARKETING_VERSION` (1.0.0)
      for both targets, but the Mac ASC row was still `1.0`, so a 1.0.0 build could not attach. Fixed on
      2026-08-24 by updating the ASC row to 1.0.0 (`asc versions update`), not by splitting the version
      per target, keep them aligned when bumping.
- [ ] `asc xcode export` only writes `.ipa`; the macOS `.pkg` needs raw `xcodebuild -exportArchive`
      with the root `ExportOptions.plist`. Worth wiring an `.asc/workflow.json` for this repo, nyc is
      the one app not covered by `asc workflow run ship-ios`.
- [ ] Light mode covers app chrome only, the tile artwork (`tile_*` textures in `Resources/`) is
      night-styled and is used unchanged in both themes, so the light theme reads as "light UI over a
      night city". `TileType.baseColor` is now dead in practice for textured tiles (it is only the
      fallback when a texture is missing). A true light world needs a second tile set, i.e. art, not code.
- [ ] Slow startup confirmed on device, not just suspected: tapping NEW GAME on an iPhone 17 Pro sim
      takes ~10-15s to reach the game, with no spinner or progress feedback, the screen simply sits on
      the menu. `GameScene.didMove` runs `WorldGenerator.generate()` and then `TileMap` builds one
      `SKSpriteNode` per tile up front. A reviewer could easily read that as a hang. Worth a loading
      state at minimum, chunked/lazy tile construction as the real fix. Relates to "Investigate slow
      startup/loading" above.

## Ingested 2026-08-24

- [ ] Come up with an original name for the game (currently just "NYC").
- [ ] Write a script that plays through the whole game end to end (regression walkthrough).
- [ ] Confirm autoplay is disabled and removed. Autoplay should only run when connected via a server, or when the playthrough script above is run explicitly. (Directive engine was deleted 2026-07, this is a verification pass, not a rebuild.)
- [ ] **Hero: game simulation (full version, deferred).** Future iteration: a canvas running a render loop with the game simulating itself, instead of the current static drifting-tile wall. Slot into `nyc/landing/index.html` the same way: absolute layer at `z-index:0` behind `.hero .container`, the `.hero::after` scrim above it, and a `prefers-reduced-motion` bail-out. **Guardrail:** this is decoration on the marketing page only, it must not resurrect the deleted directive/autoplay engine, and must not touch `Sources/`.
- [ ] **macOS screenshots still 0, and app previews still 0 on every platform.** macOS could not be
      touched this pass: MAC_OS 1.0.1 is IN_REVIEW (1.0.0 is READY_FOR_SALE), and uploading to a
      version under review can pull it out of the queue. `.asc/screenshots/mac_set/` and
      `mac_upload/` already hold 1280x800 frames, verify them against the current build, then
      upload once 1.0.1 clears.
- [ ] **Screenshot frames that must never be uploaded.** Four local iPad frames are disqualified and
      are kept only as history: `ipad-gameplay.png` and `ipad-raw.png` are the title/menu screen,
      which is exactly what drew the Guideline 2.3.3 rejection on 2026-08-26; `ipad-final.png` and
      `ipad-try2.png` carry the `nodes:16481 60.0 fps` debug counter from before the `#if DEBUG`
      gate. They also show the pre-rename "TIMES SQUARE" title, the app now reads "NYC SURVIVE".
- [ ] **Original name for the game.** "NYC Survive" is descriptive, not a name. Use the
      `asc-name-creator` skill to find an available single-word App Store name, same process as
      the Echo→Voxprint rename.
- [x] **Playthrough script.** Done 2026-10-21: `scripts/playthrough.sh` (bot in scripts/playthrough/, never in the app). A script that plays the game start to finish, for verification
      only. Must live outside `Sources/` and stay opt-in (server-driven or explicitly invoked),
      never wired into the app, see the no-autoplay rule below.
- [ ] **Confirm autoplay is gone.** Re-verify the game never plays itself in a normal session;
      the directive engine was deleted 2026-07-02 and must not have crept back.

## WebMCP + REST API rollout -- shipped 2026-08-27

Done. 6 tools: `get_game_state`, `list_saves`, `start_game`, `load_save`, `save_game`, and a gated `delete_save`.

See `docs/API.md` for the full tool table, linked from the README.

## Web menu demo game -- shipped 2026-08-28

Menu now renders a live demo game behind the scrim instead of the static skyline. Demo runs a throwaway colonist-building loop that's hard-gated on state.demoMode so real games stay fully player-controlled. Clicking NEW GAME or a save slot tweens the camera in and fades the menu out, then hands over a fresh game; the demo loop exits cleanly by loopId. Files: demo.test.mjs added, demoTick in systems.js, deployed to Cloudflare Pages.

## macOS screenshot capture, how to redo it (2026-08-27)

`Sources/App/NYCSurviveApp.swift` has a `-shot N` launch argument that skips the menu into a fresh
game and preselects a panel, so captures show the app in use rather than the title screen. This is
the fix for Guideline 2.3.3 on macOS, and the same hook makes future refreshes a one-liner.

- `-shot 1`: plain colony map
- `-shot 2`: colonist status panel open
- `-shot 3`: build menu open

Capture loop (no AppleScript / System Events involved):

1. Build Release: `xcodebuild -project NYCSurvive.xcodeproj -scheme NYCSurvive -configuration Release -derivedDataPath .asc/artifacts/mac-shots -skipPackagePluginValidation build`
2. `open -n <app> --args -shot N`, then `open -a <app>` to activate. **The activation step is
   required**, launched without it the window stays 0x0 and never lays out, and
   `CGWindowListCopyWindowInfo` reports no usable window.
3. Find the window id via `CGWindowListCopyWindowInfo` with `.optionAll` (not `.optionOnScreenOnly`
  , the window is often not "on screen" by that filter). The owner name is **`NYC Survive`** with a
   space, not `NYCSurvive`.
4. `screencapture -o -x -l <windowId>` gives a 1280x832 capture (800 content + 32pt titlebar).
5. Crop the top 32px to land on exactly 1280x800, a valid `APP_DESKTOP` size. `sips -c ... --cropOffset`
   silently does nothing here; a small CoreGraphics `cropping(to:)` helper works.
- [ ] iOS rejected 4.3(a) Spam 2026-08-26. Appeal draft: ~/Documents/Code/notes/appeal-4-3-spam.md (Resolution Center, web only).

## From Notes (imported 2026-08-27)
- [ ] App Review flagged **NYC Survive 1.0.0 for iOS** (submitted Aug 26 2026 12:57 AM PDT, submission `ee6f14f3-6fa3-4ba1-86c4-61582749fd48`). Get the reason via `asc web review show`, fix, resubmit.
nyc/ROADMAP.md

### 4.3(a) status, verified 2026-08-27
  - NYC Survive iOS 1.0.0 REJECTED under **Guideline 4.3(a) Design: Spam**, same account-level wave.
  - **NYC Survive has never shipped on iOS**: one iOS version record (1.0.0), never READY_FOR_SALE. macOS 1.0.0 is live and macOS 1.0.1 is IN_REVIEW, unaffected.
  - The appeal draft says to **hold NYC Survive** rather than reply first.
  - Repo is at 1.0.1 but the iOS record is still 1.0.0; create a 1.0.1 iOS version whenever the appeal clears.
  - Note: `asc validate` errors here with "multiple app infos found" because the macOS version is concurrently IN_REVIEW. Harmless and unrelated.
  - **This is not a per-app content problem, do not fix code and do not resubmit.** Apple's letter is byte-identical boilerplate across all five with no named comparison app. Resubmitting the same build will fail again and adds to the pattern.
  - **The appeal draft is at `~/Documents/Code/notes/appeal-4-3-spam.md` (repo root, 113 lines), NOT at `<repo>/~/Documents/Code/notes/appeal-4-3-spam.md`.** Several roadmap lines point at the per-repo path; that file does not exist in any of the five repos. Fix the pointer, do not write a second draft.
  - **Status: DRAFTED, NOT FILED.** Filing is Resolution Center, which is browser-only (`asc web review` is read-only). Blocked on Joshua. Reply order in the draft is Talli, Curvely, Doorstock; hold Sparkjar and NYC Survive.
  - Verified via API 2026-08-27: submission is UNRESOLVED_ISSUES with a single appStoreVersion item REJECTED, no phantom-IAP item, so the "mislabeled inAppPurchaseVersion" trap does not apply. `asc validate` and `asc review doctor` are otherwise clean, confirming this is a guideline call and not a readiness gap.

## TUI pilot (2026-09-05)
- `nyc-tui` SwiftPM target (SwiftTUI). `swift build && ./.build/debug/nyc-tui` lists building costs/effects from BuildingType, same scope as watchos/ (quick-reference, not a live game — the real sim runs on GameScene's SpriteKit loop). Needs a real TTY.

## Ingested 2026-10-02
- [ ] "NYC survive" (note had only the title). Survival mode for NYC, or making sure NYC survives something? Clarify.

## Ingested 2026-10-16
- [ ] Game still too confusing. Tutorial isn't playable because the window covers the build menu. Minimap doesn't work. App just needs a lot of updating. (screenshot: notes/attachments/2026-10-16/nyc-1.png)

## QA 2026-10-21 (Mac, full pass)
- [x] Balance: the game could not be won (avg level 5.2 after 200 days). Native had ported the wrong XP curve (level N cost N*100; web steps 50/100/200/300) and has no quests. Now the web curve plus 1 XP per harvest: `scripts/playthrough.sh` wins 3 of 3 worlds on days 21 to 23, about 1.5 h at 1x.
- [ ] Record the demo once it can win: `"NYC Survive.app/Contents/MacOS/NYC Survive" -demo 200` (menu, scripted tutorial, then DemoBot at 200 ticks/s, window floats on top) and record the window region with `screencapture -v -R`. Send the video.
- [ ] First click into an inactive window only focuses it; MenuSKView.acceptsFirstMouse does not get through SwiftUI's host view.
- [ ] Settings QA after the game: Full screen switch goes stale if the green window button is used; check save slots, sound, appearance.
- [ ] Design system: in-app Theme.accent is still #0071e3 next to brand blue #3d7bff; HUD mixes yellow headers, cyan tutorial titles, red SKIP. Record the NYC Sans override in CLAUDE.md and brand/BRAND.md (as Coda does).
- [ ] Landing (Joshua: C-): rebuild against hermes/landing for real, load NYC Sans from landing/fonts, add the missing dist copy step (no deploy.sh copies landing/ into dist/), deploy, check live at nyc.jaybulb.com.
- [x] Joshua 2026-10-21: refresh README and the other markdowns (done 2026-10-21); LICENSE switched to Apache 2.0; web/privacy.html checked and updated (no network calls, dated 21 Oct 2026), linked from README. Still open: link it from the landing page, which another session is rebuilding.
