# MOVEI

---

## 📖 Overview

**MOVEI** is an iOS application designed to elevate the cinema ticket booking experience. Built from the ground up with **SwiftUI** and **SwiftData**, MOVEI features an immersive full-bleed movie carousel, visual seat selection, an interactive stacked card wallet, and an authentic **physical swipe-to-tear ticket** with real-time perforation haptics and an admitted seal.

---

## ✨ Key Features

### 🎞️ 1. Hero Movie Carousel (Home)
- **Fluid Horizontal Carousel**: Swipe horizontally between featured titles (*Wicked, Brand New Day, Oppenheimer, Interstellar, Barbie, The Batman, and more*).
- **Stationary Safe-Area Anchor**: The hero poster sits behind the Dynamic Island and status bar with zero vertical bounce or pull-down disruption.
- **Movie Metadata**: High-resolution backdrop art, Rotten Tomatoes / IMDb-style ratings, genres, runtime, tagline, and direct booking triggers.

### 🎟️ 2. Dynamic Movie Wallet
- **Layered 3D Card Stack**: Displays upcoming cinema passes with peek cards stacked behind the active ticket.
- **Gesture Navigation**: Swipe left or right on the main ticket card or tap any background peek card to bring it forward.
- **Pass Counter**: Dynamic badge displaying active pass count.
- **"All Passes" Browser**: Compact overview list below the stack with instant card selection.
- **Wallet Pass Management (Three-Dots Menu)**:
  - **Delete Active Pass**: Removes the currently selected movie ticket.
  - **Clear All Passes**: Batch-clears the wallet with confirmation modal protection.
  - **Context Menus**: Long-press any ticket in the "All Passes" list to delete it individually.

### ✂️ 3. Physical Swipe-to-Tear Ticket
- **Clean Perforation Line**: Located directly above the barcode with authentic circular edge notches and dotted perforation stitches.
- **Real-Time Drag Haptics**: Swiping your finger across the dotted line provides continuous mechanical perforation feedback (`UIImpactFeedbackGenerator(style: .rigid)` per stitch).
- **Spring-Animated Separation**: Completing the tear smoothly opens a clean `18pt` vertical space between the movie pass and the detached barcode stub.
- **Ink-Stamped "ADMITTED" Seal**: Stamped across the barcode with a red dashed border, checkmark seal, and showtime timestamp.
- **"Tape Ticket Back"**: Restore and re-tear the pass at any time.
- **Wallet Return**: Top-left `< Wallet` navigation button returns directly to the Movie Wallet.

### 💺 4. Interactive Booking Flow
- **Theater Selection**: Choose between nearby theaters (*Cinemax Colombo, Scope Cinemas, Majestic City*).
- **Showtime Picker**: Select upcoming screening times.
- **Interactive Seat Picker**: Visual seat grid with live selection state and automatic price calculation.
- **Barcode Generation**: Automatically generates a native Code 128 barcode (`CICode128BarcodeGenerator`) and unique ticket ID (`MOV-XXXXXX`).

### 📱 5. Clean Bottom Navigation
- Modern, floating glassmorphism tab bar with 4 primary destinations:
  1. **Home**: Full-screen hero carousel & spotlights
  2. **Movies**: Browse cinema lineup & search
  3. **Wallet**: Stacked passes, management & ticket inspection
  4. **Profile**: User account & cinema settings

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Language** | Swift (Swift 5.10 / Swift 6) |
| **Framework** | SwiftUI |
| **Persistence** | SwiftData (`@Model TicketRecord`) |
| **Sensory Feedback** | `UIImpactFeedbackGenerator` & `UINotificationFeedbackGenerator` |
| **Imaging & Barcodes** | CoreImage (`CICode128BarcodeGenerator`) |
| **Architecture** | Declarative State-Driven Architecture |

---

## 📂 Project Structure

```text
MOVEI/
├── README.md
├── MOVEI/
│   ├── MOVEI.xcodeproj
│   └── MOVEI/
│       ├── MOVEIApp.swift       # App Entry point & SwiftData ModelContainer setup
│       ├── ContentView.swift    # Core UI, Models, Views, Wallet & Ticket interactions
│       └── Assets.xcassets      # App icons, colors, and asset catalog
```

### Key Source Components in `ContentView.swift`

- **`TicketRecord`**: SwiftData `@Model` storing ticket IDs, cinema, date, seats, and status.
- **`Movie` & `sampleMovies`**: Cinema catalog data model with backdrops, ratings, and taglines.
- **`HomeView` & `HomeFeaturedPage`**: Full-screen horizontal paging carousel.
- **`WalletView`**: Stacked pass deck, peek cards, three-dots management menu, and pass browser.
- **`TicketDetailView`**: Tearable movie pass with tear animation and admitted seal.
- **`InteractiveTicketTearBar`**: Gesture detector and haptic engine for perforation tearing.
- **`BarcodeView`**: CoreImage-powered Code 128 vector barcode generator.
- **`BookingView`**: Theater selection, showtime picker, and interactive seat selector.

---

## 🚀 Getting Started

### Prerequisites
- macOS Sonoma (14.0) or later
- Xcode 15.0 or later (Xcode 16 recommended)
- iOS 17.0+ Simulator or physical device

### Building & Running via Xcode
1. Clone or navigate to the project directory:
   ```bash
   cd /path/to/MOVEI
   ```
2. Open the project in Xcode:
   ```bash
   open MOVEI/MOVEI.xcodeproj
   ```
3. Select an iOS Simulator (e.g., **iPhone 16 Pro** or **iPhone 15**) as the target.
4. Press `Cmd + R` to build and run.

### Building & Running via Command Line
```bash
# Build the project for iOS Simulator
xcodebuild -project MOVEI/MOVEI.xcodeproj \
           -scheme MOVEI \
           -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
           build

# Run in an active simulator
xcrun simctl launch booted swifts.MOVEI
```

---

## 🧪 Testing Features in the App

1. **Test the Movie Carousel**:
   - On the **Home** tab, swipe horizontally left and right to transition between movies. Notice that vertical pulling does not rubber-band near the status bar.
2. **Test Ticket Tearing**:
   - Switch to the **Wallet** tab and tap on the active ticket pass.
   - Swipe your finger from left to right along the dotted line above the barcode.
   - Feel the incremental haptic clicks as each stitch snaps, followed by the spring separation and red **ADMITTED** stamp.
   - Tap **"Tape Ticket Back"** to restore the ticket.
   - Tap **"< Wallet"** in the top left to return to your wallet.
3. **Test Wallet Pass Management**:
   - On the **Wallet** tab, tap the **`•••`** button in the top-right corner.
   - Tap **"Delete Active Pass"** to remove the active ticket, or tap **"Clear All Passes"** to clear the wallet with confirmation.
   - Long-press any ticket in the **"ALL PASSES"** list to delete it via its context menu.

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
