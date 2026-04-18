# MediReminder 💊

A comprehensive iOS medicine reminder app built with **SwiftUI**, **SwiftData**, **Firebase Authentication**, and **Cloud Firestore**.

## Features

### 1. Medicine Management
- Add, edit, and delete medicines
- Track medicine name, dosage, form (tablet/capsule/syrup/etc.), and instructions
- Set start and end dates
- Mark medicines as active or completed

### 2. User Accounts & Private Data
- Email/password sign in and account creation with Firebase Authentication
- Each signed-in user only loads their own medicines, reminders, and dose history
- Firestore-backed sync with a local SwiftData cache for the active account
- Device registration so reminder scheduling stays tied to the current signed-in device

### 3. Smart Reminder System
- Set multiple reminder times per medicine
- Choose frequency: Daily, Every Other Day, Weekly, or Custom
- Local notifications with **Take**, **Skip**, and **Snooze** action buttons
- Quick-add presets (Morning, Afternoon, Evening, Bedtime)
- Handles iOS 64 pending notification limit automatically

### 4. Dose History Tracking
- Automatic logging of taken, skipped, and missed doses
- Filter history by date range, medicine, and status
- Daily/weekly adherence percentage
- Monthly calendar view with color-coded adherence

### 5. Drug Information Search (OpenFDA API)
- Search drugs by brand or generic name
- View purpose, usage, warnings, side effects, and drug interactions
- Recent search history
- Data sourced from the U.S. FDA drug label database

## Requirements

- **Xcode 15+**
- **iOS 17.0+** (uses SwiftData and `@Observable`)
- **Swift 5.9+**
- macOS (for building and running)

## Setup Instructions

Before building, complete the Firebase setup in [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

### Option A: Using XcodeGen (Recommended)

1. **Install XcodeGen** on your Mac:
   ```bash
   brew install xcodegen
   ```

2. **Navigate to the project folder:**
   ```bash
   cd MediReminder
   ```

3. **Generate the Xcode project:**
   ```bash
   xcodegen generate
   ```

4. **Open in Xcode:**
   ```bash
   open MediReminder.xcodeproj
   ```

5. **Select a simulator or device** and press ⌘R to build and run.

### Option B: Manual Xcode Setup

1. Open **Xcode** → **File** → **New** → **Project**
2. Choose **iOS** → **App**
3. Set:
   - Product Name: `MediReminder`
   - Interface: **SwiftUI**
   - Storage: **SwiftData**
   - Language: **Swift**
4. **Delete** the auto-generated files (ContentView.swift, Item.swift, etc.)
5. **Drag and drop** all files from the `MediReminder/` source folder into the Xcode project navigator
6. Ensure all `.swift` files are added to the `MediReminder` target
7. Build and run (⌘R)

## Project Structure

```
MediReminder/
├── project.yml                          # XcodeGen project spec
├── MediReminder/
│   ├── App/
│   │   ├── MediReminderApp.swift        # @main entry point
│   │   └── AppDelegate.swift            # Notification delegate
│   ├── Models/
│   │   ├── Medicine.swift               # Medicine data model
│   │   ├── Reminder.swift               # Reminder data model
│   │   └── DoseHistory.swift            # Dose history data model
│   ├── ViewModels/
│   │   ├── MedicineListViewModel.swift  # Medicine list logic
│   │   ├── MedicineDetailViewModel.swift# Add/edit medicine logic
│   │   ├── ReminderViewModel.swift      # Reminder scheduling logic
│   │   ├── DoseHistoryViewModel.swift   # History & adherence logic
│   │   └── DrugSearchViewModel.swift    # OpenFDA search logic
│   ├── Views/
│   │   ├── ContentView.swift            # Root TabView
│   │   ├── Medicine/
│   │   │   ├── MedicineListView.swift   # Medicine list screen
│   │   │   ├── MedicineDetailView.swift # Medicine detail screen
│   │   │   └── AddMedicineView.swift    # Add medicine form
│   │   ├── Reminder/
│   │   │   ├── ReminderListView.swift   # Reminders per medicine
│   │   │   └── AddReminderView.swift    # Add reminder form
│   │   ├── History/
│   │   │   ├── DoseHistoryView.swift    # Dose history list
│   │   │   └── CalendarView.swift       # Monthly adherence calendar
│   │   ├── Search/
│   │   │   └── DrugSearchView.swift     # Drug search screen
│   │   └── Components/
│   │       ├── MedicineRowView.swift    # Medicine list row
│   │       ├── DoseBadge.swift          # Status badge component
│   │       └── TimePickerField.swift    # Time picker component
│   ├── Services/
│   │   ├── AuthService.swift            # Firebase Authentication wrapper
│   │   ├── DeviceIdentityService.swift  # Stable installation identity
│   │   ├── NotificationService.swift    # Local notification manager
│   │   ├── OpenFDAService.swift         # FDA API client
│   │   ├── PersistenceController.swift  # SwiftData configuration
│   │   ├── UserDataSyncService.swift    # Firestore sync + cache hydration
│   │   └── UserSessionStore.swift       # Signed-in user/session state
│   ├── Utilities/
│   │   ├── Extensions.swift             # Date, String, Color helpers
│   │   └── Constants.swift              # App-wide constants
│   └── Resources/
│       ├── Assets.xcassets/             # App icon & colors
│       └── Info.plist                   # App configuration
└── MediReminderTests/
    ├── ModelTests.swift                 # Data model tests
    ├── ViewModelTests.swift             # ViewModel logic tests
    └── OpenFDAServiceTests.swift        # API parsing tests
```

## Architecture

**MVVM (Model-View-ViewModel)** with SwiftUI, SwiftData, Firebase Auth, and Firestore:

- **Models**: SwiftData `@Model` classes acting as the local cache
- **Views**: Declarative SwiftUI views, no business logic
- **ViewModels**: `@Observable` classes handling state and business logic
- **Services**: Authentication, Firestore sync, notification scheduling, and API communication

## API

Drug information is fetched from the **OpenFDA API** (`https://api.fda.gov/drug/label.json`).

- No API key required for development (240 requests/minute limit)
- Register for a free key at [open.fda.gov](https://open.fda.gov/apis/authentication/) for production

## Configuration

Edit `Constants.swift` to customize:
- Snooze duration (default: 10 minutes)
- OpenFDA API key (optional)
- Notification scheduling window (default: 3 days ahead)

## Notes

- User account data is stored under the signed-in Firebase user in Cloud Firestore
- SwiftData is used as the on-device cache for the active account
- Notifications use `UNUserNotificationCenter` (local only, no push server needed)
- Signing out clears the local cache and cancels pending reminders on that device
- The app handles iOS's 64 pending notification limit by refreshing schedules on app foreground

## License

This project is for educational/personal use.
