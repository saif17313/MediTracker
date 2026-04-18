# 🩺 MediReminder — Step-by-Step Setup Instructions

## What You Have

You have all the Swift source code files ready on your USB drive / cloud storage.  
Now you need to **create the Xcode project** and **run the app** on your lab Mac.

---

## 📋 Prerequisites (Check Before Starting)

- ✅ A **Mac** with **macOS 14 (Sonoma)** or later  
- ✅ **Xcode 15** or later installed (check: open Xcode → menu bar → Xcode → About Xcode)  
- ✅ The `MediReminder` folder copied to your Mac (Desktop, Documents, or any location)

---

## 🚀 METHOD 1: Using XcodeGen (Recommended — Fastest)

### Step 1: Open Terminal

1. Press **⌘ + Space** (Spotlight Search)  
2. Type **Terminal** and press **Enter**

### Step 2: Install Homebrew (if not installed)

Copy and paste this command into Terminal and press Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

- It will ask for your **Mac password** — type it (you won't see characters appearing, that's normal) and press Enter  
- Wait for it to finish (may take 2-5 minutes)  
- If it says "Already installed", skip to Step 3  

### Step 3: Install XcodeGen

```bash
brew install xcodegen
```

Wait until it finishes downloading and installing.

### Step 4: Navigate to Your Project Folder

If you copied the `MediReminder` folder to your **Desktop**:

```bash
cd ~/Desktop/MediReminder
```

If it's in **Documents**:

```bash
cd ~/Documents/MediReminder
```

> 💡 **Tip:** You can also type `cd ` (with a space after cd) and then **drag the MediReminder folder** from Finder into the Terminal window. It will auto-fill the path.

### Step 5: Generate the Xcode Project

```bash
xcodegen generate
```

You should see output like:

```
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at MediReminder.xcodeproj
```

### Step 6: Open the Project in Xcode

```bash
open MediReminder.xcodeproj
```

Xcode will launch and open your project. **Jump to the "Build & Run" section below.**

---

## 🚀 METHOD 2: Manual Xcode Setup (No Extra Tools Needed)

Use this method if you cannot install Homebrew/XcodeGen on the lab Mac.

### Step 1: Create a New Xcode Project

1. Open **Xcode** (from Applications folder or Spotlight search)  
2. Click **"Create New Project"** (or File → New → Project)  
3. Select **iOS** tab at the top  
4. Choose **App** and click **Next**  

### Step 2: Configure the Project

Fill in these settings **exactly**:

| Setting | Value |
|---------|-------|
| Product Name | `MediReminder` |
| Team | Your Apple ID (or "None" if you don't have one — you can still run on Simulator) |
| Organization Identifier | `com.medireminder` |
| Interface | **SwiftUI** |
| Storage | **SwiftData** |
| Language | **Swift** |
| Include Tests | ✅ Check this box |

5. Click **Next**  
6. Choose where to save it (Desktop is fine) and click **Create**

### Step 3: Delete Auto-Generated Files

Xcode auto-creates some files that will conflict with ours. **Delete these files:**

1. In the left sidebar (Project Navigator), expand the `MediReminder` folder  
2. **Right-click** each of these files → **Delete** → **Move to Trash**:
   - `ContentView.swift` (the auto-generated one)
   - `Item.swift`
   - `MediReminderApp.swift` (the auto-generated one)

3. Also in `MediReminderTests` folder, delete:
   - `MediReminderTests.swift` (the auto-generated one)

> ⚠️ **Important:** When Xcode asks "Remove reference or Move to Trash?" — choose **Move to Trash**

### Step 4: Copy Source Files into the Project

1. Open **Finder** and navigate to your copied `MediReminder` folder  
2. You should see these folders inside:
   ```
   MediReminder/
   ├── App/
   ├── Models/
   ├── ViewModels/
   ├── Views/
   ├── Services/
   ├── Utilities/
   └── Resources/
   ```

3. In **Xcode**, right-click on the `MediReminder` folder in the left sidebar  
4. Click **"Add Files to MediReminder..."**  
5. Navigate to your source `MediReminder/MediReminder/` folder  
6. **Select ALL folders** at once:
   - Hold **⌘ (Command)** and click each folder: `App`, `Models`, `ViewModels`, `Views`, `Services`, `Utilities`
   
7. Make sure these boxes are checked:  
   - ☑️ **Copy items if needed**  
   - ☑️ **Create groups**  
   - ☑️ Target: **MediReminder** is checked  
   
8. Click **Add**

### Step 5: Add Test Files

1. In Xcode's left sidebar, right-click on the `MediReminderTests` folder  
2. Click **"Add Files to MediReminder..."**  
3. Navigate to your source `MediReminder/MediReminderTests/` folder  
4. Select all 3 test files:
   - `ModelTests.swift`
   - `ViewModelTests.swift` 
   - `OpenFDAServiceTests.swift`
5. Check: ☑️ Copy items if needed, ☑️ Target: **MediReminderTests**  
6. Click **Add**

### Step 6: Verify Info.plist

1. In the left sidebar, find `Resources/Info.plist`
2. Click on the **MediReminder project** (the blue icon at the very top of the sidebar)  
3. Select the **MediReminder** target  
4. Go to the **Build Settings** tab  
5. Search for `Info.plist`  
6. Set the value to: `MediReminder/Resources/Info.plist`

> If the Info.plist was already auto-configured by Xcode, you may skip this step.

### Step 7: Verify Asset Catalog

1. Make sure `Assets.xcassets` appears in the Project Navigator  
2. If it doesn't show up, right-click the `Resources` group → Add Files → select the `Assets.xcassets` folder

---

## ▶️ BUILD & RUN (Both Methods)

### Step 1: Set the iOS Deployment Target

1. Click on the **MediReminder project** (blue icon, top of left sidebar)  
2. Select the **MediReminder** target  
3. Go to **General** tab  
4. Under **Minimum Deployments**, set **iOS** to **17.0**

### Step 2: Select a Simulator

1. At the top of Xcode, click the device selector (it shows something like "Any iOS Device")  
2. Choose a simulator, for example:
   - **iPhone 15 Pro** ← Recommended  
   - or **iPhone 15**
   - or **iPhone 16 Pro** (if available)

### Step 3: Build the Project

Press **⌘ + B** (Command + B) to build.

- ✅ If you see **"Build Succeeded"** — great! Continue to Step 4.  
- ❌ If you see errors, see the **Troubleshooting** section below.

### Step 4: Run the App

Press **⌘ + R** (Command + R) to run.

- The iOS Simulator will launch  
- The MediReminder app will appear on the simulated iPhone  
- You should see the **Medicines** tab with an empty state

### Step 5: Test the App

Try these things to verify everything works:

1. **Add a Medicine:**
   - Tap the **+** button (top right)
   - Enter: Name = "Aspirin", Dosage = "500mg", Form = "Tablet"
   - Add instructions: "Take after food"
   - Tap **Save**

2. **Set a Reminder:**
   - Tap on the medicine you just added
   - Tap **Reminders** button
   - Tap the **+** button
   - Select a time and tap **Add**
   - Allow notifications when prompted

3. **Search a Drug:**
   - Tap the **Drug Search** tab (magnifying glass icon)
   - Search for "Aspirin" or "Ibuprofen"
   - Tap a result to see full drug information

4. **Check History:**
   - Go back to your medicine
   - Tap **Take Now** or **Skip**
   - Switch to the **History** tab to see the recorded dose

---

## ⚠️ TROUBLESHOOTING

### Error: "No such module 'SwiftData'"
- **Fix:** Make sure your deployment target is iOS 17.0 or later  
- Project → Target → General → Minimum Deployments → iOS 17.0

### Error: "@Observable requires iOS 17"
- **Fix:** Same as above — set deployment target to iOS 17.0

### Error: "Duplicate symbol" or "Multiple commands produce"  
- **Fix:** You might have duplicate files. Check that you don't have two copies of `MediReminderApp.swift` or `ContentView.swift`  
- Delete any auto-generated duplicates

### Error: "Cannot find type 'Medicine' in scope"
- **Fix:** Make sure all `.swift` files are added to the **MediReminder** target  
- Select each file in the sidebar → check the **File Inspector** (right panel) → Target Membership → ☑️ MediReminder

### Error: "Failed to initialize ModelContainer"
- **Fix:** Clean the build folder: **Product** menu → **Clean Build Folder** (⌘ + Shift + K)  
- Then build again (⌘ + B)

### Simulator doesn't launch
- **Fix:** Go to **Xcode** menu → **Settings** → **Platforms** → make sure **iOS 17** simulator runtime is installed  
- If not, click the **+** button to download it

### Notifications don't appear in Simulator
- Notifications **do** work in the Simulator, but:
  - You need to tap "Allow" when the permission dialog appears on first launch
  - The app must be in the **background** (press ⌘ + Shift + H to go to home screen) for banner notifications to appear
  - If the app is in the foreground, the banner still shows (we configured that)

### OpenFDA Search returns no results
- **Fix:** Make sure your Mac has **internet access**
- Try common drug names: "Aspirin", "Ibuprofen", "Amoxicillin", "Metformin"
- The API is case-insensitive

---

## 🏃 QUICK REFERENCE (Cheat Sheet)

| Action | Shortcut |
|--------|----------|
| Build | ⌘ + B |
| Run | ⌘ + R |
| Stop | ⌘ + . |
| Clean Build Folder | ⌘ + Shift + K |
| Show/Hide Navigator | ⌘ + 0 |
| Show/Hide Inspector | ⌘ + Option + 0 |
| Open Simulator Home | ⌘ + Shift + H |
| Run Tests | ⌘ + U |

---

## 📱 Running on a Physical iPhone (Optional)

If you want to run on a **real iPhone** instead of the Simulator:

1. Connect your iPhone to the Mac with a USB cable  
2. On your iPhone: **Settings → Privacy & Security → Developer Mode → Turn ON** (restart required)  
3. In Xcode: click the device selector → choose your iPhone  
4. You need an **Apple ID** signed in:  
   - Xcode → Settings → Accounts → Add Apple ID  
5. In the project settings → Signing & Capabilities → Team → select your Apple ID  
6. Press ⌘ + R to build and install  
7. On first run, your iPhone may say "Untrusted Developer":  
   - Go to iPhone → Settings → General → VPN & Device Management → Trust your developer certificate

---

## 📁 Files You Should Have

Make sure your `MediReminder` folder contains all of these before starting:

```
MediReminder/
├── project.yml                          ← For XcodeGen (Method 1)
├── README.md                            ← This file
├── MediReminder/
│   ├── App/
│   │   ├── MediReminderApp.swift        ← App entry point
│   │   └── AppDelegate.swift            ← Notification handling
│   ├── Models/
│   │   ├── Medicine.swift               ← Medicine data model
│   │   ├── Reminder.swift               ← Reminder data model
│   │   └── DoseHistory.swift            ← Dose tracking model
│   ├── ViewModels/
│   │   ├── MedicineListViewModel.swift
│   │   ├── MedicineDetailViewModel.swift
│   │   ├── ReminderViewModel.swift
│   │   ├── DoseHistoryViewModel.swift
│   │   └── DrugSearchViewModel.swift
│   ├── Views/
│   │   ├── ContentView.swift            ← Main tab view
│   │   ├── Medicine/
│   │   │   ├── MedicineListView.swift
│   │   │   ├── MedicineDetailView.swift
│   │   │   └── AddMedicineView.swift
│   │   ├── Reminder/
│   │   │   ├── ReminderListView.swift
│   │   │   └── AddReminderView.swift
│   │   ├── History/
│   │   │   ├── DoseHistoryView.swift
│   │   │   └── CalendarView.swift
│   │   ├── Search/
│   │   │   └── DrugSearchView.swift
│   │   └── Components/
│   │       ├── MedicineRowView.swift
│   │       ├── DoseBadge.swift
│   │       └── TimePickerField.swift
│   ├── Services/
│   │   ├── NotificationService.swift
│   │   ├── OpenFDAService.swift
│   │   └── PersistenceController.swift
│   ├── Utilities/
│   │   ├── Extensions.swift
│   │   └── Constants.swift
│   └── Resources/
│       ├── Assets.xcassets/
│       │   ├── Contents.json
│       │   ├── AppIcon.appiconset/
│       │   │   └── Contents.json
│       │   └── AccentColor.colorset/
│       │       └── Contents.json
│       └── Info.plist
└── MediReminderTests/
    ├── ModelTests.swift
    ├── ViewModelTests.swift
    └── OpenFDAServiceTests.swift
```

**Total: 27 Swift files + 4 JSON/Plist resources + 2 config files = 33 files**

---

Good luck with your project! 🎉
