# Binu (formerly HeraHub)

**Level of Achievement:** Apollo 11

**Mission:** Foster an inclusive, safe, and intelligent platform for real-time support, education, and emergency aid around women’s health—accessible by everyone, regardless of gender.

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [User Stories](#user-stories)

   * [Female Students](#female-students)
   * [Male Students](#male-students)
3. [Core Features](#core-features)

   * [Women’s Forum](#womens-forum)
   * [ML-Powered Sentiment Classification](#ml-powered-sentiment-classification)
   * [Period Necessities Sharing System](#period-necessities-sharing-system)
   * [HeraHub: Education Center](#herahub-education-center)
   * [Emergency Contacts Feature](#emergency-contacts-feature)
4. [Installing BinuApp for Testing](#installing-binuapp-for-testing)
5. [Design Philosophy](#design-philosophy)
6. [Tech Stack](#tech-stack)
7. [Folder Structure](#folder-structure)
8. [Unit Testing](#unit-testing)
9. [Usability Testing](#usability-testing)
10. [Problems Encountered](#problems-encountered)

---

## Problem Statement

University students often face barriers in accessing credible, empathetic, and stigma-free platforms to discuss and manage women’s health-related issues. Female students feel vulnerable discussing topics like menstrual health, sexual wellbeing, or pregnancy concerns due to societal judgment and digital traceability. Meanwhile, male students are left out of these conversations entirely—creating an empathy and knowledge gap that impacts relationships, peer support, and overall campus health culture.

Binu addresses the pressing lack of privacy‑conscious, health‑focused, and gender‑inclusive digital spaces on university campuses by combining anonymous social interaction, emergency support, and real‑time education.

---

## User Stories

### Female Students

* **Anonymous Posting:** “I want to post about my health concerns without revealing my identity,” to overcome shame or fear.
* **Urgent Supply Requests:** “I want to request menstrual products from nearby users when I need them urgently,” especially during campus emergencies.
* **Supportive Advice:** “I want to access relationship advice from people with similar lived experiences,” which feels more comforting than clinical advice.
* **Emergency Contacts:** “I want to quickly find campus or national helplines,” because in crises, time and clarity are critical.

### Male Students

* **Educational Support:** “I want to learn how periods work so I can support my girlfriend respectfully,” without awkward questions.
* **Emotional Guidance:** “I want quick advice on how to be emotionally supportive during my partner’s cycle,” to avoid causing stress.
* **Responsible Knowledge:** “I want to understand topics like pregnancy and consent,” so I can act responsibly and speak accurately among friends.

---

## Core Features

### Women’s Forum (Completed)

A secure, anonymous discussion board for women to share questions, stories, and support.

* **Post Creation:** Title, text, optional images, sentiment tagging, and engagement data.
* **Commenting:** Add, edit, delete replies as subcollections.
* **Likes:** Toggle likes stored in Firestore.
* **Real-Time Updates:** `ForumViewModel` & `CommentViewModel` with Combine.
* **Lazy Loading:** Smooth scrolling without UI freezes.

### ML-Powered Sentiment Classification (Completed)

On‑device sentiment analysis tags posts as **positive**, **neutral**, or **negative** to guide empathetic responses.

* **Sentiment Enum:**

  * Positive: `NLTagger` score > 0.1
  * Negative: score < -0.1
  * Neutral: otherwise
* **Implementation:** Apple’s NLTagger runs on device; badges appear in UI before saving posts.

### Period Necessities Sharing System (In Progress)

Peer‑to‑peer requests for menstrual products via Bluetooth LE.

* **Item Selection:** `Item` enum encodes requests (pads, tampons, pills) into UInt8.
* **Bluetooth Broadcasting:** `BroadcastService` advertises with a unique UUID (energy‑efficient, \~10–15m range).
* **Geo-Tagged Requests:** Coordinates sent after acceptance.
* **Live Peer Discovery:** Background receivers see and notify near requests.
* **Receiver Interface:** View requests, items, and proximity.

> **Status:** Backend logic (broadcast/receive) is partially complete; persistent reconnection and UI flows remain under development.

### HeraHub: Real-Time Women’s Health Education Center (Mostly Completed)

Aggregates RSS feeds from credible sources (UN Women, CNA, HealthHub SG).

* **SupportCard.swift:** Data model for title, link, image, summary.
* **CombinedFeedLoader.swift:** XML parsing into `SupportCard` objects; segregates by source.

> **Status:** Live updates on launch; planning offline caching for critical content.

### Emergency Contacts Feature (In Progress)

In‑app directory of institutional helplines.

* **Categories:** Medical, mental health, safety, peer support.
* **Tap-to-Call:** One‑tap dialing.
* **Location‑Aware:** Campus‑specific contacts.

---

## Installing BinuApp for Testing

### Prerequisites

* **macOS:** Ventura 13.5 or later.
* **Xcode:** 15.0 or later.

### Download & Install

1. Download the compressed app bundle:
   [https://drive.google.com/file/d/1lMLtRsbZ_2MLkMb5YQEk2rKTY6DS8gfM/view?usp=sharing](https://drive.google.com/file/d/1lMLtRsbZ_2MLkMb5YQEk2rKTY6DS8gfM/view?usp=sharing)
2. Unzip the file; you’ll have `BinuApp.app` in `~/Downloads`.
3. Launch Xcode and open **Simulator** (**Open Developer Tool > Simulator**).
4. Drag `BinuApp.app` into the simulator window—it installs automatically.

### Troubleshooting

* **Unable to install:** Ensure Simulator OS ≥ iOS 17.0 and Xcode ≥ 15.0.

  ```bash
  xcrun simctl shutdown booted && xcrun simctl boot booted
  ```

---

## Design Philosophy

* **Single Responsibility:** Modules handle one concern only.
* **MVVM Pattern:**

  * Model: Domain logic.
  * View: SwiftUI rendering.
  * ViewModel: State & logic.
* **Interface Segregation:** Small, testable protocols (e.g., `AuthService`, `BroadcastService`).
* **Unit Testing:** Dependency injection enables mocked Firestore, Sentiment, Bluetooth.

---

## Tech Stack

* **Languages & Frameworks:** Swift, SwiftUI, Combine, CoreBluetooth, MultipeerConnectivity, CoreLocation, Apple NLTagger
* **Backend & Cloud:** Firebase Firestore, Storage, Authentication (via `GoogleService-Info.plist`)

---

## Folder Structure

```
BinuApp/
├── AppEntry.swift
├── Assets.xcassets/
├── ContentView.swift
├── Extensions/
│   └── UIImageExtension.swift
├── Models/
│   ├── Forum/
│   └── UserModel.swift
├── Services/
│   ├── Auth/
│   ├── Forum/
│   └── PeerToPeer/
├── ViewModels/
│   ├── Auth/
│   ├── Forum/
│   ├── HeraHub/
│   ├── PeerToPeer/
│   └── Profile/
├── Views/
│   ├── Auth/
│   ├── Forum/
│   ├── HeraHub/
│   ├── MainTab/
│   ├── PeerToPeer/
│   ├── Profile/
│   └── Shared/
└── Tests/
    └── BinuAppTests.swift
```

---

## Unit Testing

We use **XCTest** to validate core logic, error handling, and state changes independently of UI or hardware.

* Example: `BroadcastServiceTests.swift` mocks `PeripheralManager` to verify advertising behavior and service lifecycle.

---

## Usability Testing

* **Self‑Evaluation:** Cognitive walkthroughs of key features; resolved issues in navigation and layout.
* **High‑Fidelity Prototypes (In Progress):** Testing with target users to optimize help request flows.

---

## Problems Encountered

1. **Bluetooth Connectivity:** Background scanning limits led to flaky peer discovery. Ongoing improvements in error handling and reconnection logic.
2. **UI Crashes:** Occasional freezes during request flows. Expanding unit tests to isolate and fix issues.
3. **Repo Collaboration:** Merge conflicts from concurrent work. Adopted feature‑branch workflow, PR reviews, and daily syncs.

---
