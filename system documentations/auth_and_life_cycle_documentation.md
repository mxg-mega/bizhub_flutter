# Authentication & User Lifecycle Documentation

## 1. Overview
The application uses **Firebase Authentication** as the primary identity provider, integrated with **Firestore** for profile persistence, **Firebase Custom Claims** for administrative authorization, and a **Multi-Tenant Membership** model to allow users to participate in multiple businesses.

---

## 2. Technical Architecture

### 2.1 The `useAuth` Hook (Orchestrator)
The `useAuth` hook (`src/hooks/use-auth.tsx`) manages the global authentication state using a reactive `valtio` store.

- **Persistence Layer**: 
  - **Firebase Auth**: Authoritative session and identity.
  - **Firestore User Document**: `/users/{uid}` (Syncs `displayName`, `email`, `photoURL`, and `updatedAt`).
  - **Valtio Store**: Reactive local state (`authStore`) for real-time UI updates across the application.

### 2.2 User Enhancement (`enhanceUser`)
Upon login, the system "enhances" the Firebase User object:
1. **Token Refresh**: Forces an ID token refresh to retrieve the latest Custom Claims.
2. **SuperAdmin Check**: Verifies if the user is a platform-wide SuperAdmin via the `AuthApi`.
3. **Membership Resolution**: Fetches all businesses the user is linked to from the `/users/{uid}/memberships` collection.
4. **Claim Mapping**: Hydrates the `user` object with flags like `isSuperAdmin` and `isAdmin` (Business-level Admin).

---

## 3. UI Flows & Logic

### 3.1 Sign-In Flow (`/sign-in`)
1. **Interaction**: User provides Email/Password or uses Google Auth.
2. **Action**: `signInWithEmailAndPassword` or `signInWithPopup`.
3. **Post-Auth Logic**:
   - `onAuthStateChanged` triggers `updateUserState`.
   - `enhanceUser` resolves memberships and active `businessId`.
   - **Persistence**: If no `businessId` claim exists, the user is prompted to select or create a business.
4. **Redirection**: Redirects to the dashboard or a pending invitation link.

### 3.2 Sign-Up & Onboarding (`/sign-up`)
1. **Account Creation**: Creates the identity record in Firebase Auth.
2. **Business Initialization**:
   - User inputs Business Name and Category.
   - **Transactional Setup**:
     - Creates the root `/businesses/{id}` document.
     - Adds the user as the first member in `/businesses/{id}/team/{uid}` with `role: 'Owner'`.
     - Links the business in `/users/{uid}/memberships/{id}`.
     - Seeds default roles (Owner, Admin, Cashier, Member).
3. **Status**: User is redirected to the dashboard as the new Business Owner.

### 3.3 Invitation Acceptance (`/accept-invite`)
1. **Landing**: User lands with an `inviteId` from an email magic link.
2. **Verification**:
   - Validates that the invitation exists and is still `pending`.
   - Ensures the logged-in user's email matches the invite's recipient email.
3. **Transaction**:
   - Updates the invitation status to `accepted`.
   - Adds the business to the user's membership list.
   - Adds the user to the business's team sub-collection.

---

## 4. Authorization & Security

### 4.1 Security Layers
- **Route Guards**: Middleware and layout-level checks ensure users cannot access `/dashboard` paths without a valid `businessId`.
- **Component Guards**: `hasPermission()` hook hides/shows UI elements based on the active role's `permissionsMap`.
- **Firestore Rules**: Rules enforce that a user can ONLY read/write data in a business path if their `uid` exists in the business's `team` sub-collection.

### 4.2 JIT (Just-In-Time) Migration
For users transitioning from the legacy single-tenant system:
- `runJitMigration` detects if the user has data in the legacy `/users/{uid}` path but no active business.
- It automatically migrates inventory, sales, and settings into a new `/businesses/{id}` scope.

---

## 5. Developer Best Practices
1. **Auth Dependency**: Always use `useAuth()` to access user data. Do not rely on `firebase.auth().currentUser` as it lacks membership and claim context.
2. **Email Verification**: Some modules (like high-value transfers) should check `user.emailVerified` before allowing the action.
3. **Loading States**: Use the `isLoading` flag from `useAuth` to prevent "flicker" or "flash of unauthenticated content" during the `enhanceUser` phase.
