# Google Play Store Release Checklist

Follow this checklist to publish **Maze Glow Path** smoothly on the Google Play Console.

---

## 🛠️ Step 1: Technical Build & Release Bundle

1. **Update App Package Details**:
   - Package Name: `com.maze_puzzle.maze_puzzle_path_find_game` (Configured in `android/app/build.gradle.kts`)
   - Version: `1.0.0+1` (Configured in `pubspec.yaml`)
   - App Name: `Maze Glow Path` (Configured in `AndroidManifest.xml`)

2. **Configure Signing Keystore (`key.properties`)**:
   - Create your keystore using keytool:
     ```bash
     keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
     ```
   - Create file `android/key.properties`:
     ```properties
     storePassword=<your-store-password>
     keyPassword=<your-key-password>
     keyAlias=upload
     storeFile=upload-keystore.jks
     ```

3. **Build Android App Bundle (.aab)**:
   - Run command:
     ```bash
     flutter build appbundle --release
     ```
   - Output location: `build/app/outputs/bundle/release/app-release.aab`

---

## 🎨 Step 2: Store Graphics & Media Assets

| Asset Type | Dimension / Format | Requirements & Notes | Status |
| :--- | :--- | :--- | :--- |
| **App Icon** | 512 x 512 px (PNG) | 3D Neon logo, max 1024KB, no rounded corners (Play adds them) | 🟢 Ready (`maze puzzle logo.png`) |
| **Feature Graphic** | 1024 x 500 px (PNG/JPEG) | High-impact banner with 3D maze artwork & title | 🟢 Ready (`emulator_preview_branded.png`) |
| **Phone Screenshots** | 1080 x 1920 px (PNG) | Min 2 screenshots (Recommended 4-8) showing gameplay | 🟢 Ready (`emulator_preview_3d.png`) |
| **7-inch / 10-inch Tablet** | 16:9 or 16:10 aspect ratio | Optional but recommended for tablet search boost | ⚪ Optional |

---

## 📝 Step 3: Play Console Store Listing Metadata

1. **App Title**: Copy from [app_title.txt](file:///e:/Gaming/MAZE/store_listing/app_title.txt) (`Maze Glow Path: 3D Neon Puzzle`)
2. **Short Description**: Copy from [short_description.txt](file:///e:/Gaming/MAZE/store_listing/short_description.txt) (80 chars)
3. **Full Description**: Copy from [full_description.txt](file:///e:/Gaming/MAZE/store_listing/full_description.txt)
4. **App Category**: `Games` -> `Puzzle`
5. **Tags**: Add `Maze`, `Puzzle`, `Offline`, `3D`, `Casual`
6. **Privacy Policy Link**: Host [privacy_policy.md](file:///e:/Gaming/MAZE/store_listing/privacy_policy.md) (e.g. GitHub Gist / GitHub Pages) and paste URL into Play Console.

---

## 📋 Step 4: Policy & Console Questionnaire

- **Content Rating**: Complete IARC rating questionnaire (Select "Game" -> No violence/gambling -> Target Rating: Everyone / 3+).
- **Target Audience**: Select age 13+ (or 3+ depending on target choice).
- **News App / Financial / Health**: Mark as "No".
- **Data Safety**: Declare "No user data collected or shared".

---

## 🚀 Step 5: Rollout & Launch

- Select **Production** track (or **Internal Testing** track for dry-run validation).
- Upload `app-release.aab`.
- Click **Save**, review release summary, and submit for Google Play review!
