# Requirements Document

## Introduction

BeerCo is currently offline-first: all data (tables, members, orders, table events) lives in a local Hive store, isolated per install, and never leaves the device. This feature introduces a shared cloud backend so the same data is visible across iOS, Android, and (future) Web for the same account. A user can create a table with members and orders on mobile and later see it on Web.

The app must remain offline-capable: a local cache continues to serve reads and accept writes without a connection, and changes reconcile with the cloud when connectivity returns. Accounts/authentication are introduced so ownership of a table is known (supporting the forward-looking "creator chip" that today shows the table-name initial offline and should show the signed-in user's avatar/initial when online).

This document is intentionally backend-agnostic where possible. The design phase will recommend a concrete backend (Supabase or Firebase) that operates within a free tier. Requirements express observable behavior and constraints, not implementation.

This spec is planning only. No application code is produced by this document.

## Glossary

- **App**: The BeerCo Flutter client running on iOS, Android, or Web.
- **Cloud_Backend**: The remote service (Supabase or Firebase, chosen in design) that stores accounts and synced records and enforces access rules.
- **Auth_Service**: The component of the Cloud_Backend responsible for account creation, sign-in, session/token management, and identity.
- **Sync_Engine**: The App-side component that reconciles the Local_Cache with the Cloud_Backend (pushing local changes, pulling remote changes).
- **Local_Cache**: The on-device store (Hive or equivalent) that persists records for offline use.
- **Repository**: The existing data-access abstraction (TableRepository, OrderRepository) through which all UI reads and writes flow. Cloud sync plugs in behind this layer; UI code is not changed by sync mechanics.
- **Record**: A synced domain entity: a Table, Member, Order, or Table_Event.
- **Table**: A domain entity representing a group tab (TableModel).
- **Member**: A person attached to a Table (MemberModel).
- **Order**: A drink order attached to a Table and Member (OrderModel).
- **Table_Event**: An audit entry for a Table (TableEventModel), e.g. paid / active_again.
- **User**: An authenticated identity with an account in the Auth_Service.
- **Owner**: The User who created a Table; recorded as the Table's creator.
- **Collaborator**: A User, other than the Owner, who has been granted access to a Table.
- **Sync_Status**: The App-visible state of a Record or of the App as a whole: one of `synced`, `pending`, `syncing`, `error`, `offline`.
- **Free_Tier**: The no-cost usage limits of the chosen Cloud_Backend (e.g. storage, rows/documents, bandwidth, monthly active users).
- **Connectivity**: Whether the App currently has a working network path to the Cloud_Backend.
- **Session**: An authenticated period for a User, backed by a token that the Auth_Service can refresh or expire.

## Requirements

### Requirement 1: Account creation and sign-in

**User Story:** As a BeerCo user, I want to create an account and sign in, so that my tables are tied to my identity and visible across my devices.

#### Acceptance Criteria

1. WHEN a person submits valid sign-up credentials, THE Auth_Service SHALL create a User account and establish an authenticated Session.
2. WHEN a User submits valid sign-in credentials, THE Auth_Service SHALL establish an authenticated Session for that User.
3. IF sign-up or sign-in credentials are invalid, THEN THE App SHALL display an error message describing the failure and SHALL leave the User signed out.
4. WHEN a User signs out, THE App SHALL end the Session and SHALL retain locally cached Records for offline viewing.
5. WHILE a valid Session exists, THE App SHALL associate cloud reads and writes with the signed-in User.
6. WHEN an existing Session token expires, THE Auth_Service SHALL refresh the Session without requiring the User to re-enter credentials, provided the refresh credential is still valid.
7. IF Session refresh fails because the refresh credential is no longer valid, THEN THE App SHALL return the User to the sign-in screen and SHALL preserve locally cached Records.

### Requirement 2: Anonymous / offline-first use before sign-in

**User Story:** As a first-time user, I want to use the app without an account, so that I can try it before committing to sign-up.

#### Acceptance Criteria

1. WHILE no User is signed in, THE App SHALL allow creation and viewing of Tables, Members, Orders, and Table_Events using the Local_Cache.
2. WHILE no User is signed in, THE App SHALL mark locally created Records with Sync_Status `offline`.
3. WHEN a person who created local-only Records signs in for the first time, THE App SHALL offer to associate the existing local-only Records with the newly signed-in User.
4. WHERE the person accepts association of local-only Records, THE Sync_Engine SHALL upload those Records to the Cloud_Backend as owned by the signed-in User.
5. WHERE the person declines association of local-only Records, THE App SHALL keep those Records accessible in the Local_Cache without uploading them to the Cloud_Backend.
6. IF one offline operation among creation, viewing, modification, and deletion becomes unavailable, THEN THE App SHALL continue to offer the remaining offline operations.

### Requirement 3: Ownership and creator identity

**User Story:** As a user, I want each table to record who created it, so that the creator chip can show the owner and access can be attributed.

#### Acceptance Criteria

1. WHEN a signed-in User creates a Table, THE App SHALL record that User as the Owner of the Table.
2. THE Cloud_Backend SHALL store, for each Table, the Owner identity and the Table creation timestamp.
3. WHILE a User is signed in and online, THE App SHALL display the Owner's avatar or initial in the creator chip of a Table the User can access.
4. WHILE no User is signed in, THE App SHALL display the Table-name initial in the creator chip.
5. THE Cloud_Backend SHALL store, for each User, a display name and an optional avatar reference used by the creator chip.
6. IF a Table has no recorded Owner or the Owner information is unavailable, THEN THE App SHALL display an "unknown owner" placeholder indicator in the creator chip.

### Requirement 4: Cloud data model mapping

**User Story:** As a developer, I want the local models mapped to cloud records with stable identities, so that the same entity is recognizable across devices.

#### Acceptance Criteria

1. THE Cloud_Backend SHALL persist Tables, Members, Orders, and Table_Events as distinct Record types.
2. THE Sync_Engine SHALL use each Record's existing string identifier as the Record's stable cloud identity.
3. THE Cloud_Backend SHALL preserve the parent references of each Record, associating each Member, Order, and Table_Event with its Table, and each Order and Table_Event with its Member.
4. THE Sync_Engine SHALL preserve every field of each local model when mapping to a cloud Record, including Member payment state, Member avatar reference, and Order quantity.
5. THE Cloud_Backend SHALL store, for each Record, a last-modified timestamp and the identifier of the User who last modified the Record.
6. WHEN a Record is deleted, THE Sync_Engine SHALL propagate the deletion to the Cloud_Backend and to other devices with access, regardless of whether the deletion originated from a User action or an automated process.

### Requirement 5: Offline-first local cache

**User Story:** As a user with an unreliable connection, I want the app to keep working offline, so that I can manage a table without waiting for the network.

#### Acceptance Criteria

1. THE App SHALL read every Record from the Local_Cache so that reads succeed without Connectivity.
2. WHILE Connectivity is unavailable, THE App SHALL accept creation, modification, and deletion of Records into the Local_Cache.
3. IF a local write cannot be completed because Local_Cache storage is full or local data integrity cannot be maintained, THEN THE App SHALL fail that individual write with an error message and SHALL leave other Records unchanged.
4. WHEN a Record is written to the Local_Cache while offline, THE App SHALL set that Record's Sync_Status to `pending`.
5. WHEN Connectivity is restored, THE Sync_Engine SHALL upload all `pending` Records to the Cloud_Backend.
6. WHEN a `pending` Record is confirmed stored by the Cloud_Backend, THE App SHALL set that Record's Sync_Status to `synced`.
7. IF an upload of a `pending` Record fails or times out after Connectivity is restored, THEN THE App SHALL keep that Record's Sync_Status as `pending` and THE Sync_Engine SHALL retry the upload later.

### Requirement 6: Synchronization across devices

**User Story:** As a user with multiple devices, I want changes on one device to appear on my others, so that my data stays consistent everywhere.

#### Acceptance Criteria

1. WHEN a signed-in User changes a Record on one device and Connectivity is available, THE Sync_Engine SHALL upload the change to the Cloud_Backend.
2. WHEN the Cloud_Backend holds a change to a Record the User can access, THE Sync_Engine SHALL make that change available to the User's other devices.
3. WHERE the chosen Cloud_Backend supports real-time updates, THE App SHALL reflect remote changes to a viewed Table within 5 seconds of the change being stored, while the App is open and online.
4. WHERE real-time updates are not enabled, THE App SHALL refresh Records from the Cloud_Backend when a Table is opened and when the User triggers a manual refresh.
5. WHERE real-time updates are enabled, THE App SHALL rely on the real-time stream to keep a viewed Table current and SHALL skip the refresh-on-open behavior.
6. WHEN the Sync_Engine applies a remote change, THE App SHALL update the Local_Cache so that later offline reads return the updated Record.

### Requirement 7: Conflict handling

**User Story:** As a user, I want concurrent edits to resolve predictably, so that data is not silently lost when two devices change the same table.

#### Acceptance Criteria

1. WHEN the Sync_Engine detects that a local change and a remote change apply to the same Record, THE Sync_Engine SHALL resolve the conflict using last-modified timestamp, keeping the most recently modified version.
2. IF a local change and a remote change to the same Record have identical last-modified timestamps, THEN THE Sync_Engine SHALL keep the remote version.
3. WHEN a conflict is resolved in favor of the remote version, THE App SHALL update the Local_Cache to match the retained version.
4. IF a local Record and a remote Record share an identifier but represent an add on each side, THEN THE Sync_Engine SHALL retain a single Record identified by that identifier without creating a duplicate.
5. WHEN one device deletes a Record and another device modifies the same Record before syncing, THE Sync_Engine SHALL keep the deletion and SHALL propagate the deletion to all devices with access.

### Requirement 8: Access control

**User Story:** As a table owner, I want control over who can read and write my table, so that unauthorized users cannot see or change my data.

#### Acceptance Criteria

1. THE Cloud_Backend SHALL restrict read access to a Table and its Members, Orders, and Table_Events to the Owner and Collaborators of that Table.
2. THE Cloud_Backend SHALL restrict write access to a Table and its Members, Orders, and Table_Events to the Owner and Collaborators of that Table.
3. IF an unauthenticated request attempts to read or write a Record, THEN THE Cloud_Backend SHALL reject the request.
4. IF an authenticated User attempts to read or write a Table the User is neither Owner nor Collaborator of, THEN THE Cloud_Backend SHALL reject the request.
5. WHEN the Owner grants a Collaborator access to a Table, THE Cloud_Backend SHALL allow that Collaborator to read and write the Table and its child Records.

### Requirement 9: Free-tier constraints and usage limits

**User Story:** As the product owner, I want the solution to run within a free tier, so that operating cost stays at zero for expected usage.

#### Acceptance Criteria

1. THE Cloud_Backend configuration SHALL operate within the documented Free_Tier limits of the selected provider for storage, record count, bandwidth, and monthly active users.
2. THE design SHALL document the selected provider's Free_Tier limits, including the storage ceiling (for example, approximately 1 GB for Firebase Firestore), and the estimated usage for an expected user base.
3. WHERE stored data approaches a configured fraction of the Free_Tier storage ceiling, THE App SHALL surface a warning to the affected User.
4. THE Sync_Engine SHALL batch or debounce uploads so that a single rapid sequence of local changes does not exceed the provider's per-User request-rate limits.

### Requirement 10: Migration of existing local-only data

**User Story:** As an existing user with local-only data, I want my current tables preserved when I sign in, so that adopting accounts does not lose my history.

#### Acceptance Criteria

1. WHEN a User signs in on a device that holds local-only Records, THE App SHALL preserve those Records in the Local_Cache.
2. WHEN local-only Records are associated with a signed-in User, THE Sync_Engine SHALL upload them to the Cloud_Backend as owned by that User without altering their identifiers, timestamps, or field values.
3. IF a local-only Record shares an identifier with a Record already stored in the Cloud_Backend, THEN THE Sync_Engine SHALL resolve the pair using the conflict rules of Requirement 7 rather than creating a duplicate.
4. WHEN the Cloud_Backend confirms successful storage of a migrated Record, THE App SHALL set that Record's Sync_Status to `synced`.
5. IF migration of a local-only Record fails or is interrupted, THEN THE App SHALL keep that Record's Sync_Status as `pending` and SHALL retry migration later.

### Requirement 11: Connectivity and error handling

**User Story:** As a user, I want clear feedback about sync state and failures, so that I know whether my data is saved and can trust the app.

#### Acceptance Criteria

1. THE App SHALL display the current App-level Sync_Status among `synced`, `pending`, `syncing`, `error`, and `offline`.
2. WHEN Connectivity is lost, THE App SHALL set the App-level Sync_Status to `offline` and SHALL continue to serve reads and writes from the Local_Cache.
3. WHILE Connectivity is unavailable, THE App SHALL treat `offline` as the App-level Sync_Status in preference to `syncing` or `synced`, so that connectivity state takes precedence over sync activity.
4. IF an upload to the Cloud_Backend fails due to a transient network error, THEN THE Sync_Engine SHALL retry the upload with increasing delay between attempts.
5. IF an upload to the Cloud_Backend fails due to a rejection by access control, THEN THE App SHALL set the affected Record's Sync_Status to `error` and SHALL surface the failure to the User.
6. WHILE uploads or downloads are in progress and Connectivity is available, THE App SHALL set the App-level Sync_Status to `syncing`.
7. WHEN all `pending` Records have been confirmed stored and Connectivity is available, THE App SHALL set the App-level Sync_Status to `synced`.
8. THE App SHALL set the App-level Sync_Status to `synced` only after every `pending` Record has been confirmed stored by the Cloud_Backend.

### Requirement 12: Repository abstraction and web-readiness

**User Story:** As a developer, I want cloud sync to plug in behind the existing repository layer, so that UI code and web-readiness rules stay intact.

#### Acceptance Criteria

1. THE App SHALL expose Records to the UI through the existing Repository abstraction, so that adding cloud sync does not require UI screens to access the Local_Cache or Cloud_Backend directly.
2. THE Repository abstraction SHALL expose asynchronous and stream-friendly read APIs so that the UI can react to Cloud_Backend updates without synchronous storage calls.
3. THE App SHALL guard any platform-locked API behind an abstraction or conditional import so that the client remains buildable for Web.
4. THE App SHALL perform navigation through go_router with URL paths so that Web back-navigation, direct links, and refresh continue to function.
5. WHERE a new backend client dependency is added, THE dependency SHALL declare Web support.
