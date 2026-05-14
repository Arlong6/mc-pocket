# TestFlight + App Store submission

The code is ready. These are the steps **you** have to do manually because they require your Apple Developer credentials.

## 1. Apple Developer account (one-time, $99/yr)

- developer.apple.com → enroll in the Apple Developer Program
- Note your **Team ID** (10-char string, found under Account → Membership)

## 2. App ID + certificates

Visit <https://developer.apple.com/account/resources/identifiers>:
1. Click **+** → App IDs → App
2. Bundle ID: `com.arlong.mcpocket` (exact match with project.yml)
3. Capabilities: enable **Push Notifications**
4. Register

For the embedded targets (Xcode will auto-register if signing is automatic):
- `com.arlong.mcpocket.widgets`
- `com.arlong.mcpocket.watchkitapp`

## 3. APNs Auth Key

Visit <https://developer.apple.com/account/resources/authkeys>:
1. **+** → Key Name: "MC Pocket APNs"
2. Enable **Apple Push Notifications service (APNs)**
3. Continue → Register → **Download the .p8 file** (you only get to download once)
4. Note the **Key ID** (10 chars) and your **Team ID** (from step 1)

Move the `.p8` somewhere safe on your Mac, e.g. `~/Library/MissionControl/AuthKey_<KEYID>.p8`.

Then in Mission Control (Mac) → ⌘, → iOS Remote tab, set:
- Team ID, Key ID, Bundle ID = `com.arlong.mcpocket`, path to .p8
- Toggle "Use production APNs" once you're shipping (TestFlight builds use production too)

## 4. Enable signing

Edit `project.yml`:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: YOUR_TEAM_ID    # add this
    CODE_SIGNING_ALLOWED: YES         # flip from NO
    CODE_SIGN_STYLE: Automatic
```

Then regenerate:
```bash
xcodegen generate
```

Also fill in `app-store/ExportOptions.plist` with your `teamID`.

## 5. App Store Connect listing

Visit <https://appstoreconnect.apple.com>:
1. **My Apps** → **+** → New App
2. Platform: iOS · Name: MC Pocket · Primary Language: English (or 繁中)
3. Bundle ID: `com.arlong.mcpocket` (should appear after step 2 above)
4. SKU: `mc-pocket-v1`
5. Fill in remaining fields from `app-store/AppStoreMetadata.md`
6. Upload Privacy Policy URL (publish `PRIVACY-POLICY.md` to GitHub Pages first)
7. Add at least 3 6.9" iPhone screenshots (see screenshot list in AppStoreMetadata.md)

## 6. Build, archive, upload

From the repo root:

```bash
# Increment build number
plutil -replace CFBundleVersion -string "1" Sources/MCPocket/Info.plist  # auto-set

# Archive
xcodebuild -project MCPocket.xcodeproj \
  -scheme MCPocket \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/MCPocket.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/MCPocket.xcarchive \
  -exportOptionsPlist app-store/ExportOptions.plist \
  -exportPath build/Export \
  -allowProvisioningUpdates

# Upload (needs an App Store Connect API key — easier with Transporter.app)
xcrun altool --upload-app \
  -f build/Export/MCPocket.ipa \
  --type ios \
  --apiKey <KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

Alternative simpler path: open `build/MCPocket.xcarchive` in **Xcode Organizer** → Distribute App → App Store Connect. GUI walks you through.

## 7. TestFlight

Once the build appears in App Store Connect (5–15 min after upload):
1. App Store Connect → TestFlight tab
2. Add yourself as an Internal Tester
3. Install **TestFlight** app on your iPhone, accept the invite
4. Test the pairing flow with your live Mac (with Mission Control v0.2.0+ running)
5. Verify pushes, Live Activity, rules, Watch app

## 8. Submit for App Store review

When TestFlight feels solid (give yourself a week of personal use):
1. App Store Connect → App Store tab → +Version (1.0)
2. Pick the TestFlight build
3. Add review notes:

```
This app is a self-hosted companion for an open source Mac menubar app
(Claude Mission Control, github.com/Arlong6/claude-mission-control).

To test the app, the reviewer will see mock data on first launch ("AIvideo",
"CarFinder", etc.) without needing to pair to a Mac. The pairing flow requires
the Mac-side app, which is provided as source code only — for App Review
purposes, the mock data demonstrates all UI surfaces.

The app has no third-party backend. All data flows between the user's own iPhone
and their own Mac over local network or Tailscale, plus APNs from the user's
Mac to Apple Push.
```

4. Demo account: **Not required** (mock data shown on first launch)
5. Submit. Apple usually reviews within 24h for utility apps.

## Common rejection reasons (avoid these)

- **No demo on first launch** → mock data is shown by default until paired. Make sure this still works.
- **Push without explanation** → already addressed in `NSCameraUsageDescription` / `NSLocalNetworkUsageDescription`.
- **External instructions** → don't tell users to "visit our website to set up." The app shows the QR-scan flow in-product.
- **Background modes claimed but unused** → we use `remote-notification` legitimately for APNs.

## After approval

- Tag the release: `git tag v0.1.0 && git push --tags`
- Update README to mark v0.1.0 shipped
- Drop a note on the claude-mission-control repo linking MC Pocket
