# Binu

Level of Achievement: Apollo 11

To foster a supportive community regarding women's health, for both Men and Women.

This README includes requirements for Milestone 1, and provides instructions for cloning, configuring, and running the app locally.

---

## Table of Contents

1. [Project Motivation and Statement](#problem-statement)
2. [Proposed Core Features](#core-features)
3. [Tech Stack, Proposed Design and Plan](#tech-stack-and-design)
4. [Prerequisites](#prerequisites)  
5. [Clone the Repository](#clone-the-repository)  
6. [Install Dependencies](#install-dependencies)  
7. [Configure Firebase](#configure-firebase)  
8. [Open and Run in Xcode](#open-and-run-in-xcode)  
9. [Environment Variables & Secrets](#environment-variables--secrets)  
10. [Folder Structure](#folder-structure)  
11. [Troubleshooting](#troubleshooting)  

---

## Problem Statement

University students, particularly women, often lack a safe, judgment-free space to discuss sensitive personal topics such as menstrual health, relationships, pregnancy concerns, and sexual health. Many hesitate to seek advice publicly due to stigma and privacy concerns. Additionally, there is a lack of awareness among male students regarding menstruation, hormonal changes, and relationship dynamics, which can lead to misunderstandings and inadequate support.


Our project aims to bridge this gap by:

- Creating a social-media-like platform for women to anonymously discuss sensitive topics.
- Facilitating sharing of period necessities (pads, tampons) through a location-based request system, akin to TraceTogether.
- Educating men on menstrual health and relationship support through an interactive learning interface.

---

## Proposed Core Features

### User Stories

For Women:
1. As a female university student who feels uncomfortable discussing period-related topics publicly, I want to join a safe online community where I can ask questions and share experiences anonymously.
2. As a woman who unexpectedly ran out of menstrual products, I want to request pads/tampons from nearby users so I don’t have to leave campus or go to a store in an emergency.
3. As a student struggling with relationship issues, I want to read advice from other women who have had similar experiences.
4. As a student on campus, I want an emergency contact feature to quickly access women’s health clinics, counselors, and helplines.

For Men:
1. As a male student who wants to better understand menstruation, I want access to simple, clear educational content that helps me support my girlfriend or female friends.
2. As a boyfriend who wants to be more caring during my partner’s period, I want tips on how to comfort her and avoid common mistakes.
3. As a male student unfamiliar with pregnancy and sexual health topics, I want access to professional guidance to ensure I am well-informed.

### Core Features

Women's Social Forum
- A private and anonymous discussion board for female students to discuss sensitive topics such as menstrual health, relationships, pregnancy and mental well-being
- Users can ask questions, post experiences, and upvote helpful responses
- ML Powered Sentiment classification of topics
- Female gender will be verified to access the forum

Period Necessities Sharing System
- Location-based "Help Request" feature to ping nearby female users when in urgent need of pads/tampons
- Users receive a notification when someone nearby is requesting or offering menstrual products

HeraHub
- A hub for education and resources on women's health
- AI Chatbot to answer common period and relationship queries
- Emergency contact and support locator

Cycle Tracker
- Anticipate and predict periods based on previously recorded information

---

## Tech Stack and Design

1. Swift & SwiftUI
2. Firebase Storage & Cloud Firestore
3. OpenAI API

### Design Philosophy
Single Responsibility Principle
- Each class or struct should have one clear responsibility.
- See Folder Structure for examples.

MVVC (Model-View-ViewController) Design Pattern
- Model: Represents App data and business logic. Models are Swift types (structs, classes) independent of the UI

- View: Purely for rendering the user interface. Contains SwiftUI views

- ViewController: Sits between the Model and View. Responsible for owning the View (loading or instantiating the View), binds Models to Views (fetches data from Models) and handles user actions (such as tapping a button or scrolling) by updating the View when required.

Interface Segregation Principle (ISP)
- Prefer smaller, specific protocols over large general ones.

Unit Testing
- Set up a Unit Testing Bundle and tested using the built in XCTest Framework for fast testing. Determine test case inputs and outputs in advance, before implementing it.

---

## Prerequisites

- **macOS 13.0+**  
- **Xcode 15.0+** (ensure Command Line Tools are installed)  
- **Swift Package Manager (Built-in to Xcode)**
- **Git** (for cloning the repo)  
- **A Firebase project** (to obtain `GoogleService-Info.plist`)  

---

## Clone the Repository

1. Open Terminal.  
2. Navigate to your desired parent directory:
   ```bash
   cd ~/Projects
   ```
3. Clone this repository:
   ```bash
   git clone https://github.com/ryan-toh/BinuApp.git
   ```
4. Change into the directory:
   ```bash
   cd BinuApp
   ```

---

## Install Dependencies

### Using Swift Package Manager

1. Open the Xcode project (`.xcodeproj`).
2. Navigate to **File → Add Packages...**  
3. Search for each dependency and add the correct version:
   - `Firebase`: https://github.com/firebase/firebase-ios-sdk  
   - Any other SPM packages (e.g., Alamofire, Kingfisher, etc.)
4. Xcode will automatically resolve and fetch SPM dependencies.

---

## Configure Firebase

1. In your Firebase console, create or select a project.  
2. In **Project Settings → General → Your apps**, click **Add app** and choose **iOS+**.  
3. Enter your **iOS bundle ID** (e.g., `com.yourcompany.myapp`).  
4. Download the generated **`GoogleService-Info.plist`** file.  
5. **Copy** `GoogleService-Info.plist` into the Xcode project: 
   - drag `GoogleService-Info.plist` into Xcode’s Project Navigator under the root folder.  
6. Confirm that in Xcode, `GoogleService-Info.plist` is included under **Build Phases → Copy Bundle Resources**.
7. Return to the firebase console. Ensure that you are in the **overview tab** of the project you just created.
8. **Enable Email/Password Authentication**
   1. In the Firebase Console, click **Authentication** in the left sidebar.
   2. Select the **Sign-in method** tab.
   3. Under **Sign-in providers**, locate **Email/Password** and click **Edit** (pencil icon).
   4. Toggle **Enable** to **On**, then click **Save**.
   5. (Optional) Under **Templates → Email address confirmarion/Password reset**, you can customize the email templates if desired.  
   6. Now your project will accept new user registrations and sign-ins via email and password.
   
9. **Configure Firestore Rules for Full Read/Write (Development Only)**
   > ⚠️ These rules permit anyone (authenticated or not) to read and write all documents. Only use for development.  
   1. In the Firebase Console, click **Firestore Database** in the left sidebar.
   2. Select the **Rules** tab.
   3. Replace any existing rules with the following:
      ```js
      service cloud.firestore {
        match /databases/{database}/documents {
          // Allow full read/write for every document:
          match /{allPaths=**} {
            allow read, write: if true;
          }
        }
      }
      ```
   4. Click **Publish**.  
   5. Once published, any client (even if not signed in) can perform reads and writes on Firestore.  
   6. **IMPORTANT**: Before going to production, these rules must be locked down (e.g., `allow read, write: if request.auth != null && …`). For now, they remain wide open to facilitate front-end development.
   
10. **Configure Storage Rules for Full Read/Write (Development Only)**
    > ⚠️ These rules permit anyone (authenticated or not) to upload, download, or delete any file. Only use for development.  
    1. In the Firebase Console, click **Storage** in the left sidebar.
    2. Select the **Rules** tab.
    3. Replace any existing rules with:
       ```js
       service firebase.storage {
         match /b/{bucket}/o {
           // Allow full read/write on every path:
           match /{allPaths=**} {
             allow read, write: if true;
           }
         }
       }
       ```
    4. Click **Publish**.  
    5. Now any client (even if not signed in) can upload, download, or delete any file in your Storage bucket.


---

## Open and Run in Xcode

1. Open the workspace or project:
   - **SPM**:  
     ```bash
     open MyApp.xcodeproj
     ```
2. Select a simulator or a physical device in the toolbar’s device selector.  
3. Build the project (⌘B).  
4. Run the app (⌘R).  
5. The first launch may take a moment as Firebase initializes.

---

## Environment Variables & Secrets

- **`GoogleService-Info.plist`** is not included in version control. Make sure each developer adds their own file.  

---

## Folder Structure

```
.
├── BinuApp
│   ├── AppEntry.swift
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   ├── Contents.json
│   │   │   └── logo.png
│   │   └── Contents.json
│   ├── ContentView.swift
│   ├── Extensions
│   │   └── UIImageExtension.swift
│   ├── Item.swift
│   ├── Models
│   │   ├── Forum
│   │   │   ├── CommentModel.swift
│   │   │   ├── PostImageModel.swift
│   │   │   ├── PostModel.swift
│   │   │   └── SentimentModel.swift
│   │   └── UserModel.swift
│   ├── Preview Content
│   │   └── Preview Assets.xcassets
│   │       └── Contents.json
│   ├── Services
│   │   ├── Auth
│   │   │   ├── AuthService.swift
│   │   │   └── UserService.swift
│   │   └── Forum
│   │       ├── CommentService.swift
│   │       ├── PostService.swift
│   │       └── SentimentService.swift
│   ├── ViewModels
│   │   ├── Auth
│   │   │   ├── AuthViewModel.swift
│   │   │   └── OnboardingViewModel.swift
│   │   ├── Forum
│   │   │   └── ForumViewModel.swift
│   │   ├── HeraHub
│   │   │   └── LibraryViewModel.swift
│   │   ├── PeerToPeer
│   │   │   └── PeerToPeerViewModel.swift
│   │   └── Profile
│   │       └── AccountViewModel.swift
│   └── Views
│       ├── Auth
│       │   ├── LoginView.swift
│       │   ├── Onboarding
│       │   │   └── EnterUsernameView.swift
│       │   ├── SignUpView.swift
│       │   └── WelcomeView.swift
│       ├── Forum
│       │   ├── CreatePostView.swift
│       │   ├── ForumView.swift
│       │   └── PostRowView.swift
│       ├── HeraHub
│       │   └── LibraryView.swift
│       ├── MainTab
│       │   └── MainTabView.swift
│       ├── PeerToPeer
│       │   └── PeerToPeerView.swift
│       ├── Profile
│       │   └── AccountView.swift
│       └── Shared
│           ├── ErrorBannerView.swift
│           ├── LoadingSpinnerView.swift
│           ├── NotReadyView.swift
│           └── Text Boxes
│               └── FullWidthTextBox.swift
├── BinuAppTests
│   └── BinuAppTests.swift
├── BinuAppUITests
│   ├── BinuAppUITests.swift
│   └── BinuAppUITestsLaunchTests.swift
└── README.md
```

---

## Troubleshooting

- **“`GoogleService-Info.plist` not found”**  
  - Ensure you added the file to the project and that it’s included in **Targets → Build Phases → Copy Bundle Resources**.

- **“Permission denied” errors on Firestore or Storage**  
  - Inspect your Firebase Rules in the console to ensure full read/write access is allowed.  
