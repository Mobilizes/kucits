# KucITS — Technical Design Document

**Project:** KucITS (Kucing ITS)
**Course:** Mobile Programming (PPB) B
**Platform:** Android (primary), iOS, Web (secondary)
**Framework:** Flutter 3.x * Dart ^3.11
**Backend:** Firebase (Auth, Cloud Firestore, Messaging, Crashlytics), ImgBB (Image Storage)

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

| For                   | Value                                                        |
| --------------------- | ------------------------------------------------------------ |
| Students / Cat lovers | Discover campus cats, follow their stories, share encounters |
| Department Admins     | Maintain an accurate database of cats in their area          |
| Campus community      | A shared social feed that brings joy and connection          |

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
- Cloud Storage Services (ImgBB for images)
- Firebase Crashlytics (Real-time crash reporting)

---

## 3. Current Implementation Status

### 3.1 What Is Built (Implemented)

| Area                   | Details                                                                                                                                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Firebase Setup**     | Firebase Core, Auth, and Firestore SDKs integrated. Multi-platform config.                                                                                                                                                            |
| **Authentication**     | Full email/password auth and anonymous guest sign-in. Integrated with GoRouter redirection.                                                                                                                                           |
| **Auth Service**       | `AuthService` class wrapping `FirebaseAuth`.                                                                                                                                                                                          |
| **Theme System**       | Custom Material 3 theme with Montserrat font and ITS Blue. Dark mode uses neutral gray palette, and settings persist via `shared_preferences`.                                                                                        |
| **Timeline Screen**    | Scrollable feed with `RefreshIndicator`, showing real posts streamed from Firestore.                                                                                                                                                  |
| **Compose Screen**     | Full-screen compose screen with cat tagging, caption length validation, location tagging selection, and Firestore post creation.                                                                                                      |
| **User Profile**       | Tab 3 displaying user initials, bio, post count chip, and a 3-column photo grid of the user's posts.                                                                                                                                  |
| **Settings Screen**    | Dedicated settings screen (`/settings`) for dark mode toggling and account sign-out with confirmation.                                                                                                                                |
| **Map Integration**    | Fully functional Map tab (`/map`) displaying markers for cat sightings, and `LocationPickerScreen` for selecting coordinates on a map when composing posts.                                                                           |
| **Media & Cropping**   | Image selection uses `image_picker`, custom cropping uses `image_cropper` (1:1 square for cat profiles, free aspect ratio loop for sightings posts), and compression uses `flutter_image_compress` prior to Firebase Storage uploads. |
| **Cat Database**       | Fully integrated database screen, collapsible map overlay, faculty/department cascading dropdown filters, sterilization choice chips, and grid view.                                                                                  |
| **Moderation & Likes** | Admin check gates (`isAdmin` profile checks), admin-only FAB/edit/delete buttons, unified add/edit cat form, orphan post safeguards, and transaction-based like/comment mechanisms.                                                   |
| **Push Notifications** | Firebase Messaging integrated: permission request, FCM token saved to Firestore user doc on login, foreground in-app banners via `ScaffoldMessengerKey`, background/terminated tap handler.                                           |
| **Crashlytics**        | Firebase Crashlytics integrated: Flutter framework errors forwarded via `FlutterError.onError`, async/platform errors via `PlatformDispatcher.instance.onError`, Crashlytics Gradle plugin enabled.                                   |
| **Data Models**        | `Cat`, `CatPost`, `UserProfile`, and `Comment` models with Firestore serialisation.                                                                                                                                                   |

> [!IMPORTANT]
> **Backend Configuration Requirement**:
> 1. **ImgBB Setup**: You must provide an ImgBB API key in `lib/config/env.dart` for image uploads to work.
> 2. **Firestore Indexes**: Create the required composite indexes for Firestore (a query error link will print in the VS Code debug console upon visiting a cat details page for the first time).
> 3. **Push Notifications**: To send push notifications to users (e.g., on comment/like), use the Firebase Console → Cloud Messaging → Send test message, targeting the FCM token stored in each user's Firestore doc (`users/{uid}/fcmToken`).

### 3.2 What Is Placeholder / Not Yet Functional (Pending)

None. All Phase 2-6 features are fully functional and integrated.

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

### Actual Structure

```text
lib/
├── main.dart
├── firebase_options.dart
├── app/
│   ├── router.dart
│   ├── theme.dart
│   └── theme_provider.dart
├── config/
│   ├── env.dart                  # API keys (ImgBB)
│   └── env.dart.example
├── models/
│   ├── cat.dart
│   ├── cat_post.dart
│   ├── comment.dart
│   └── user_profile.dart
├── screens/
│   ├── home/
│   │   └── home_shell.dart       # Bottom nav shell
│   ├── admin_cat_form_screen.dart
│   ├── cat_database_screen.dart
│   ├── cat_detail_screen.dart
│   ├── compose_screen.dart
│   ├── location_picker_screen.dart
│   ├── login_screen.dart
│   ├── map_screen.dart
│   ├── notifications_screen.dart
│   ├── post_detail_screen.dart
│   ├── profile_management_screen.dart
│   ├── register_screen.dart
│   ├── reset_password_screen.dart
│   ├── settings_screen.dart
│   ├── timeline_screen.dart
│   └── user_profile_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── cat_service.dart
│   ├── database_service.dart
│   ├── notification_service.dart
│   ├── post_service.dart
│   ├── storage_service.dart
│   └── user_service.dart
└── widgets/
    ├── compose_box.dart
    ├── map_view_overlay.dart
    └── post_card.dart
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

### 7.2 Storage Structure (ImgBB)

Images (avatars, cat icons, and post photos) are uploaded directly to ImgBB via its REST API. The resulting direct image URLs are then saved as string fields within the respective Firestore documents.

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
- **Media**: Users can upload up to 4 photos per post. To prevent excessive bandwidth and storage usage, images are automatically downscaled and compressed on the client side (e.g., max 1080p, JPEG quality 80) using the `flutter_image_compress` package before uploading to ImgBB.
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

| Package                  | Purpose                                       |
| ------------------------ | --------------------------------------------- |
| `flutter` (SDK)          | Core framework                                |
| `firebase_core`          | Firebase initialisation                       |
| `firebase_auth`          | Authentication                                |
| `cloud_firestore`        | Database                                      |
| `http`                   | REST API calls (ImgBB photo uploads)          |
| `firebase_messaging`     | Push notifications (Mandatory Spec)           |
| `firebase_crashlytics`   | Real-time crash reporting (Bonus Spec)        |
| `provider`               | State management and dependency injection     |
| `go_router`              | Declarative routing and redirect logic        |
| `shared_preferences`     | Persistent local key-value settings storage   |
| `google_maps_flutter`    | Interactive map integration and location tags |
| `image_picker`           | Camera/gallery access (max 4 photos)          |
| `flutter_image_compress` | Client-side image resizing and compression    |
| `cached_network_image`   | Cached image loading with placeholders        |

### 10.1 Environment Setup (Local Keys)

To configure the project locally, create the following configuration files (these are ignored by Git for security):

1. **ImgBB API Key**:
   Create `lib/config/env.dart` and add your ImgBB key:
   ```dart
   class Env {
     static const String imgbbApiKey = 'YOUR_API_KEY';
   }
   ```

2. **Google Maps API Key**:
   - **Android**: Add the API key to `android/local.properties`:
     ```properties
     GOOGLE_MAPS_API_KEY=<your_api_key>
     ```
   - **iOS**: Create `ios/Flutter/Secret.xcconfig` and add the API key:
     ```config
     GOOGLE_MAPS_API_KEY = <your_api_key>
     ```

*(Note: Google Sign-In is intentionally excluded to focus on core requirements, though it may be added later if time permits.)*

---

## 11. Development Roadmap

### Phase 1: Core Data & Auth Update `[Completed]`
- `[x]` Update Auth flow to include Username registration and validation.
- `[x]` Implement `UserService` for profile creation and reading.
- `[x]` Implement `CatService` for reading the Cat Database.
- `[x]` Setup `Provider` for state management.

### Phase 2: Cat Database & Admin Tools `[Completed]`
- `[x]` Build the Cat Database screen (list and filtering by department/faculty/sterilization status).
- `[x]` Implement Admin checks (`isAdmin == true` security gates and dynamic buttons).
- `[x]` Build Admin UI to add, edit, and remove cats.
- `[x]` Integrate `image_cropper` for 1:1 square cropping on cat profile photos.

### Phase 3: Post Creation & Storage `[Completed]`
- `[x]` Integrate `image_picker` and `http` (ImgBB) for handling up to 4 images.
- `[x]` Integrate `image_cropper` for multi-image free aspect ratio cropping on sighting posts.
- `[x]` Integrate `google_maps_flutter` for location tagging in posts.
- `[x]` Wire `ComposeScreen` to write complete `CatPost` documents to Firestore (including client-side image compression).

### Phase 4: Forum, Timeline & Map Integration `[Completed]`
- `[x]` Update Timeline to stream real posts from Firestore.
- `[x]` Add Interactive Map (integrated directly as a collapsible `MapViewOverlay` on the Cat Database screen).
- `[x]` Implement Cat Detail screen showing sorted posts (Latest vs. Popularity).

### Phase 5: Interactions & Moderation `[Completed]`
- `[x]` Implement Like and Comment functionality.
- `[x]` Implement post deletion for authors and Admins (Moderation).
- `[x]` Ensure anonymous users are restricted from interacting (redirects to Login).

### Phase 6: Push Notifications & Crashlytics `[Completed]`
- `[x]` Integrate Firebase Messaging for user notifications.
- `[x]` Setup Firebase Crashlytics to catch and report errors.
- `[x]` Final UI polish and bug fixing.

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
