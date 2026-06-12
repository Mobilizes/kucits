# KucITS — Technical Design Document

**Project:** KucITS (Kucing ITS)
**Course:** Mobile Programming (PPB) B
**Platform:** Android (primary), iOS, Web (secondary)
**Framework:** Flutter 3.x * Dart ^3.11
**Backend:** Firebase (Auth, Cloud Firestore, Storage, Messaging, Crashlytics)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technical Requirements](#2-technical-requirements)
3. [Current Implementation Status](#3-current-implementation-status)
4. [Architecture](#4-architecture)
5. [Directory Structure](#5-directory-structure)
6. [Data Models](#6-data-models)
7. [Firebase Schema](#7-firebase-schema)
8. [Feature Specifications](#8-feature-specifications)
9. [Screen Map & Navigation](#9-screen-map--navigation)
10. [Tech Stack & Dependencies](#10-tech-stack--dependencies)
11. [Development Roadmap](#11-development-roadmap)
12. [Coding Conventions](#12-coding-conventions)
13. [Design Decisions](#13-design-decisions)

---

## 1. Project Overview

### 1.1 Concept

**KucITS** is a social-media-style mobile application built for the ITS (Institut Teknologi Sepuluh Nopember) campus community to share, discover, and keep track of campus cats. It serves as a forum to build a community around the cats in ITS. Think of it as a **Twitter/Instagram, but exclusively for campus cats**.

- **Regular Users** can post about cats they meet, tag the related cat(s), tag a location using the Google Maps API, add a caption, and attach up to 4 photos. They can scroll through posts, like, and comment. They can also view a comprehensive Cat Database containing details about each cat (name, picture, department, neutered status) and filter posts by popularity or latest.
- **Admin Users** are hand-picked by the developers. They act as moderators for the forum (able to delete inappropriate posts) and manage the Cat Database (add new cats, update statuses, remove cats). Typically, each department in ITS will have a few admins assigned to keep track of their local cats.

### 1.2 Core Value Proposition

| For                     | Value                                                          |
|--------------------------|----------------------------------------------------------------|
| Students / Cat lovers    | Discover campus cats, follow their stories, share encounters   |
| Department Admins        | Maintain an accurate database of cats in their area            |
| Campus community         | A shared social feed that brings joy and connection            |

### 1.3 Key Differentiators

- **Cat-centric posts** - Every post is centered around one or more cats.
- **Structured Cat Database** - Cats belong to departments, have neutered statuses, and serve as the core entity linking posts.
- **Department-based Moderation** - Admins manage cats specific to their departments.

---

## 2. Technical Requirements

Based on the course specifications, the app should fulfill the following:

**Mandatory Specifications:**
- Firebase Authentication
- Cloud Firestore
- Push Notifications (Firebase Messaging)
- Navigation Bar (Bottom Navigation)

**Bonus Architecture & DevOps:**
- Cloud Storage Services (Firebase Storage for images)
- Firebase Crashlytics (Real-time crash reporting)

---

## 3. Current Implementation Status

### 3.1 What Is Built (Implemented)

| Area               | Details                                                                 |
|--------------------|-------------------------------------------------------------------------|
| **Firebase Setup** | Firebase Core, Auth, and Firestore SDKs integrated. Multi-platform config. |
| **Authentication** | Full email/password auth and anonymous guest sign-in. Integrated with GoRouter redirection. |
| **Auth Service**   | `AuthService` class wrapping `FirebaseAuth`. |
| **Theme System**   | Custom Material 3 theme with Montserrat font and ITS Blue. Dark mode uses neutral gray palette, and settings persist via `shared_preferences`. |
| **Timeline Screen**| Scrollable feed with `RefreshIndicator`, showing real posts streamed from Firestore. |
| **Compose Screen** | Full-screen compose screen with cat tagging, caption length validation, and Firestore post creation. |
| **User Profile**   | Tab 3 displaying user initials, bio, post count chip, and a 3-column photo grid of the user's posts. |
| **Settings Screen**| Dedicated settings screen (`/settings`) for dark mode toggling and account sign-out with confirmation. |
| **Data Models**    | `Cat`, `CatPost`, and `UserProfile` models with Firestore serialisation. |

### 3.2 What Is Placeholder / Not Yet Functional (Pending)

| Area                     | Current State                                                            |
|--------------------------|--------------------------------------------------------------------------|
| **Map Integration**      | Campus map overlay is still a placeholder. Location tagging in posts is pending. |
| **Media Uploads**        | Post image selection (max 4 photos) and Firebase Storage upload are pending. |
| **Cat Database**         | Dedicated database screen, department filtering, and detail page are placeholders. |
| **Moderation & Likes**   | Admin check capabilities and like/comment interactions are pending. |

---

## 4. Architecture

### 4.1 Proposed Architecture

The app uses a **feature-first** structure with clear separation, utilizing **Provider** for state management and dependency injection.

```text
[ Presentation Layer ]
Screens (UI) -> ViewModels (ChangeNotifier) -> Widgets (Reusable UI)

[ Service Layer ]
AuthService, PostService, CatService (Business logic & API calls)

[ Data Layer ]
Firebase SDKs (Firestore, Auth, Storage, Messaging)
```

### 4.2 State Management Implementation
- **Dependency Injection**: A `MultiProvider` at the root (`main.dart`) will inject singleton services (e.g., `Provider<AuthService>`).
- **State Segregation**: Complex screens (like the Timeline or Compose screen) will use a `ChangeNotifier` to handle local state and business logic, separating it from the UI widget.
- **Service Pattern**: We will use a straightforward Service pattern rather than strict Repositories. Services will handle both data fetching (from Firebase) and data mapping (to models).

---

## 5. Directory Structure

### Target Structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── router.dart               # Named routes / GoRouter config
│   └── theme.dart                # Theme data extraction
├── models/
│   ├── cat.dart
│   ├── cat_post.dart
│   ├── user_profile.dart
│   └── comment.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── reset_password_screen.dart
│   ├── home/
│   │   ├── home_shell.dart       # Bottom nav shell
│   │   └── timeline_screen.dart
│   ├── compose/
│   │   └── compose_screen.dart
│   ├── profile/
│   │   ├── user_profile_screen.dart
│   │   └── edit_profile_screen.dart
│   ├── cat/
│   │   ├── cat_database_screen.dart
│   │   ├── cat_detail_screen.dart
│   │   ├── admin_add_cat_screen.dart
│   │   └── admin_edit_cat_screen.dart
│   ├── post/
│   │   └── post_detail_screen.dart
│   └── map/
│       └── campus_map_widget.dart
├── services/
│   ├── auth_service.dart
│   ├── post_service.dart
│   ├── cat_service.dart
│   ├── user_service.dart
│   ├── storage_service.dart
│   ├── location_service.dart
│   └── notification_service.dart
├── widgets/
│   ├── compose_box.dart
│   ├── post_card.dart
│   ├── comment_tile.dart
│   └── map_view_overlay.dart
└── utils/
    ├── constants.dart
    ├── validators.dart
    └── formatters.dart
```

---

## 6. Data Models

### 6.1 `UserProfile`
```dart
class UserProfile {
  final String uid;
  final String username;          // Unique, a-zA-Z0-9._
  final String profilePictureUrl;
  final String bio;
  final bool isAdmin;             // Hand-picked moderators
  final String? adminDepartment;  // If admin, which department they manage
  final DateTime lastUsernameChange;
  final DateTime createdAt;
}
```

### 6.2 `Cat`
```dart
class Cat {
  final String id;
  final String name;
  final String department;        // e.g., "Teknik Informatika", "Sistem Informasi"
  final String iconUrl;
  final bool isNeutered;
  final DateTime createdAt;
}
```

### 6.3 `CatPost`
```dart
class CatPost {
  final String id;
  final List<Cat> cats;           // Embedded cat snapshots for fast rendering
  final List<String> catIds;      // Cat document IDs for querying
  final String authorId;
  final String authorUsername;
  final String authorAvatarUrl;
  final String caption;
  final List<String> photoUrls;   // Max 4 photos
  final GeoPoint? location;       // Google Maps coordinates
  final DateTime timestamp;
  final int likes;
  final int comments;
}
```

### 6.4 `Comment`
```dart
class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String authorAvatarUrl;
  final String text;
  final DateTime timestamp;
}
```

---

## 7. Firebase Schema

### 7.1 Firestore Collections

```text
firestore-root/
│
├── users/                        # User profiles
│   └── {uid}/
│       ├── username: string
│       ├── profilePictureUrl: string
│       ├── bio: string
│       ├── isAdmin: boolean
│       ├── adminDepartment: string?
│       └── lastUsernameChange: timestamp
│
├── cats/                         # Cat database
│   └── {catId}/
│       ├── name: string
│       ├── department: string
│       ├── iconUrl: string
│       └── isNeutered: boolean
│
├── posts/                        # Global feed
│   └── {postId}/
│       ├── catIds: string[]
│       ├── authorId: string
│       ├── caption: string
│       ├── photoUrls: string[]
│       ├── location: geopoint
│       ├── timestamp: timestamp
│       ├── likes: number
│       └── commentCount: number
│
│       └── comments/             # Subcollection
│           └── {commentId}/
│               ├── authorId: string
│               ├── text: string
│               └── timestamp: timestamp
│
│       └── likes/                # Subcollection to track likes (1 doc per like)
│           └── {uid}/            # Document ID is the user's UID
│               └── timestamp: timestamp
│
└── usernames/                    # Username uniqueness enforcement
    └── {username}: {uid}
```

### 7.2 Storage Structure

```text
storage-root/
├── avatars/
│   └── {uid}.jpg                 # User profile photos
├── cat_icons/
│   └── {catId}.jpg               # Cat profile icons
└── posts/
    └── {postId}/
        ├── 1.jpg                 # Post photos (max 10MB each)
        └── 2.jpg
```

---

## 8. Feature Specifications

### 8.1 Authentication & User Profiles
- **Registration**: Users must choose a unique username (letters, numbers, dots, underscores only). Enforced via a `usernames` registry collection in Firestore.
- **Profile Data**: Users have a username, profile picture, a simple bio, and a list of their posts.
- **Username Changes**: Users can change their username a maximum of once per week.
- **Anonymous Browsing**: Unauthenticated users can view the timeline and cat database, but cannot post, like, or comment.

### 8.2 Cat Database
- **Listing**: A dedicated screen displaying all cats.
- **Filtering**: Users can filter cats by department.
- **Cat Details**: Name, photo, department, neutered status.
- **Tagged Posts**: Viewing a cat shows all posts they are tagged in, sortable by popularity (likes) or latest.

### 8.3 Post Creation (Forum)
- **Tagging**: Every post must tag at least one cat from the database.
- **Media**: Users can upload up to 4 photos per post. To prevent excessive bandwidth and storage usage, images are automatically downscaled and compressed on the client side (e.g., max 1080p, JPEG quality 80) using the `flutter_image_compress` package before uploading to Firebase Storage.
- **Location**: Users can tag a location using the Google Maps API.
- **Caption**: Text description of the encounter.

### 8.4 Timeline & Map
- **Feed**: Global scrollable feed of all posts.
- **Interactive Map**: An interactive Google Map is available on top of the main forum screen and the cat database screen, showing recent cat sightings/post locations.

### 8.5 Moderation & Admin Roles
- **Admins**: Hand-picked by developers (flagged via `isAdmin` in Firestore).
- **Post Moderation**: Admins can delete any post they deem inappropriate for the forum.
- **Database Management**: Admins can add new cats, update their statuses (e.g., department, neutered), or remove them entirely.
- **Orphaned Posts**: If an admin deletes a cat, existing posts tagged with that cat will be orphaned (the post remains, but the cat reference may resolve to a "Deleted Cat" placeholder).

### 8.6 Notifications
- **Push Notifications**: Integrated via Firebase Messaging (e.g., notifying users when their post receives a comment).

---

## 9. Screen Map & Navigation

```text
[App Start]
   |
   +-- (Not logged in) --> [Login / Register] --> (Success) --> [Home Shell]
   +-- (Anonymous) ------> [Home Shell] (Read-only)
   +-- (Logged in) ------> [Home Shell]

[Home Shell] (Bottom Navigation)
   |
   +-- Tab 1: Forum (Timeline)
   |     +-- Top: Interactive Map Overlay
   |     +-- Scrollable Feed
   |     +-- FAB: [Compose Post] (Requires Auth)
   |           +-- Tag Cats, Add Photos, Set Location
   |
   +-- Tab 2: Cat Database
   |     +-- Top: Interactive Map Overlay
   |     +-- Filter by Department
   |     +-- List/Grid of Cats
   |     +-- Tap Cat -> [Cat Detail Screen] (Info, Sorted Posts)
   |     +-- FAB: [Add Cat] (Visible to Admins only)
   |
   +-- Tab 3: Profile
         +-- [User Profile Screen]
         +-- [Edit Profile] (Change Username/Bio/Pic)
```

---

## 10. Tech Stack & Dependencies

| Package                 | Purpose                                         |
|-------------------------|-------------------------------------------------|
| `flutter` (SDK)         | Core framework                                  |
| `firebase_core`         | Firebase initialisation                         |
| `firebase_auth`         | Authentication                                  |
| `cloud_firestore`       | Database                                        |
| `firebase_storage`      | Photo uploads (posts, avatars, cat icons)       |
| `firebase_messaging`    | Push notifications (Mandatory Spec)             |
| `firebase_crashlytics`  | Real-time crash reporting (Bonus Spec)          |
| `provider`              | State management and dependency injection       |
| `go_router`             | Declarative routing and redirect logic          |
| `shared_preferences`    | Persistent local key-value settings storage     |
| `google_maps_flutter`   | Interactive map integration and location tags   |
| `image_picker`          | Camera/gallery access (max 4 photos)            |
| `flutter_image_compress`| Client-side image resizing and compression      |
| `cached_network_image`  | Cached image loading with placeholders          |

*(Note: Google Sign-In is intentionally excluded to focus on core requirements, though it may be added later if time permits.)*

---

## 11. Development Roadmap

### Phase 1: Core Data & Auth Update
- Update Auth flow to include Username registration and validation.
- Implement `UserService` for profile creation and reading.
- Implement `CatService` for reading the Cat Database.
- Setup `Provider` for state management.

### Phase 2: Cat Database & Admin Tools
- Build the Cat Database screen (list and filtering by department).
- Implement Admin checks.
- Build Admin UI to add, edit, and remove cats.

### Phase 3: Post Creation & Storage
- Integrate `image_picker` and `firebase_storage` for handling up to 4 images (10MB limit).
- Integrate `google_maps_flutter` for location tagging in posts.
- Wire `ComposeScreen` to write complete `CatPost` documents to Firestore.

### Phase 4: Forum, Timeline & Map Integration
- Update Timeline to stream real posts from Firestore.
- Add Interactive Map on top of the Forum and Database screens.
- Implement Cat Detail screen showing sorted posts (popularity/latest).

### Phase 5: Interactions & Moderation
- Implement Like and Comment functionality.
- Implement post deletion for authors and Admins (Moderation).
- Ensure anonymous users are restricted from interacting.

### Phase 6: Push Notifications & Crashlytics
- Integrate Firebase Messaging for user notifications.
- Setup Firebase Crashlytics to catch and report errors.
- Final UI polish and bug fixing.

---

## 12. Coding Conventions

### 12.1 File Naming
- All files use `snake_case.dart`
- Screens: `*_screen.dart`
- Widgets: descriptive name (e.g., `post_card.dart`, `cat_chip.dart`)
- Services: `*_service.dart`
- Models: singular noun (e.g., `cat.dart`, `cat_post.dart`)

### 12.2 Class Naming
- PascalCase for all classes: `CatPost`, `AuthService`, `TimelineScreen`
- State classes: `_ScreenNameState`
- Stateless widgets preferred unless local state is needed

### 12.3 State Management
- **Current:** Raw `setState()` within `StatefulWidget`s
- **Target:** Migrate to `Provider` for services injection and `ChangeNotifier`/`ValueNotifier` for screen state when complexity grows

### 12.4 Firestore Patterns
- Models have `fromMap(String id, Map<String, dynamic>)`, `fromSnapshot(DocumentSnapshot)`, and `toMap()` factory constructors
- Services return `Stream<List<Model>>` for real-time data, `Future<Model?>` for one-time reads
- Document IDs are assigned by Firestore (auto-ID) unless there's a natural key (e.g., user UID)

### 12.5 Error Handling
- Services currently swallow exceptions and return `null` — should evolve to use `Result` types or rethrow with custom exceptions for better UX error messages

### 12.6 UI Patterns
- **Material 3 Design System**: Implemented using custom color schemes matching the myITS Portal visual guidelines:
  - **Light Mode Colors**: Primary ITS Blue (`#004B93`), Scaffold background (`#F4F7FC`), surfaces/cards (`#FFFFFF`), main text (`#0F172A`).
  - **Dark Mode Colors**: Primary Light Blue (`#4FA1D8`), Scaffold background (`#121212` neutral gray), surfaces/cards (`#1E1E1E`), active containers (`#2C2C2C`), main text (`#F3F4F6`), secondary text (`#9CA3AF`).
- **Typography**: The primary typeface is **Montserrat** (imported via Google Fonts) for a modern, geometric look. Font guidelines use Montserrat for all headings and body text styles, replacing standard system fallbacks.
- **Theme Access**: Access colors via `Theme.of(context).colorScheme` — never hardcode hex colors in UI components.
- **Theme Toggle & Persistence**: Switch dark/light themes dynamically via a global `ThemeProvider` and settings screen switch. State is persistently saved using `shared_preferences` and reloaded on startup.
- **Seamless Gradient Backgrounds**: Auth screens use a gradient background that adapts to theme settings (blending down to `scaffoldBackgroundColor` in dark mode to ensure a seamless layout without horizontal bar overlaps).
- **Glassmorphic Card**: Semi-transparent surfaces (on light mode) or solid surfaces (on dark mode to prevent shadow transparency blending issues), rounded corners (`32`), and subtle outline borders on auth screens to give a premium design feel.
- **Responsive Layout**: Constrained layout screens utilizing a maximum width of `520` wrapped in `SingleChildScrollView`.

---

## 13. Design Decisions

- **State Management**: `Provider` will be used for state management and DI.
- **Visual Branding (myITS)**: App icon and color system are aligned directly with the ITS/DPTSI visual brand. The icon file (`assets/KucITS-icon.png`) is the official app launch icon.
- **Typography Choice**: Montserrat is utilized as the primary font to mirror the myITS web portal interface.
- **Theme Persistence**: Theme selections (dark vs. light mode) are saved in local device storage via `shared_preferences` so they are kept across app launches.
- **Clean Dark Mode Styling**: Cards use solid background fills and disable drop shadows in dark mode to prevent transparency artifacts or muddy outlines. Gradients seamlessly blend into the Scaffold's background color.
- **Core App Loop & Navigation**: Handled declaratively via `go_router` at root, showing specific tabs (Timeline, Cat Database, User Profile) and delegating theme selection/account management to a dedicated Settings route (`/settings`).
- **Backend Logic**: Sticking to client-side logic and Firestore rules (Free tier) rather than relying heavily on Cloud Functions.
- **Usernames**: Enforced unique usernames (letters, numbers, dots, underscores). Changeable once per week.
- **Cat Deletion**: If a cat is deleted by an admin, existing posts tagged with that cat will be orphaned (post remains, reference is dead/placeholder).
- **Anonymous Access**: Allowed for browsing the feed and database, but interaction (posting, liking, commenting) requires authentication. Anonymous guests can tap a "Sign In or Register" action on the Profile screen to trigger auth flow.
- **Mapping**: `google_maps_flutter` will be used to display locations and tag posts.
- **Moderation**: Hand-picked admins manage the cat database and can delete inappropriate posts.
- **Post Limits**: Users can tag multiple cats in a post. Note: due to Firestore's `array-contains-any` query limits, filtering by multiple cats at once is restricted to a maximum of 10 cats per query. Maximum of 4 photos per post, downscaled using `flutter_image_compress` before upload.
- **Follow System**: Deprioritized. The app focuses on the global forum and department-based database rather than individual follow feeds.
