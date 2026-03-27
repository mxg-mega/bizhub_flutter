# Employee Invitation & Team Onboarding Flow

## 1. Overview
The invitation system allows business owners to securely add team members by email. It ensures that only the intended recipient can join the workspace and provides a seamless onboarding experience that handles authentication, role assignment, and multi-tenant membership linking.

---

## 2. Technical Architecture

### 2.1 Firestore Collections
- **`invitations`**: A top-level collection storing pending invites.
  - Path: `/invitations/{inviteId}`
  - Schema: `{ from: string, to: string, role: Role, businessId: string, businessName: string, status: 'pending', createdAt: Timestamp }`
- **`businesses/{id}/team`**: Sub-collection tracking members of a specific business.
  - Path: `/businesses/{businessId}/team/{userId}`
  - Schema: `{ email: string, role: Role, status: 'active' | 'pending', joinedAt?: Timestamp }`
- **`users/{id}/memberships`**: Sub-collection for the user to track which businesses they belong to.
  - Path: `/users/{userId}/memberships/{businessId}`
  - Schema: `{ name: string, role: RoleName }`
- **`mail`**: Collection for triggering outgoing emails via the Firestore "Trigger Email" extension.

---

## 3. The Invitation Lifecycle

### Phase 1: Initiation (Sender Side)
1. **Trigger**: Owner/Admin uses the "Invite Member" dialog in the Users module (`src/components/users/users-table.tsx`).
2. **Hook Execution (`useMultiTeam.inviteMember`)**:
   - Validates that the email is not already a member.
   - Generates a new document in the `invitations` collection.
   - Triggers an automated email via the `mail` collection containing a magic link: 
     `${origin}/accept-invite?inviteId=${inviteId}`.
   - Creates a placeholder entry in the business's `team` sub-collection with `status: 'pending'`.

### Phase 2: Landing & Verification (Receiver Side)
1. **Landing Page**: The user clicks the link and lands on `src/app/accept-invite/page.tsx`.
2. **Verification Logic**:
   - **Invalid ID**: Displays an error if the `inviteId` doesn't exist.
   - **Auth State Check**:
     - **Not Logged In**: Redirects to `/sign-in` with `inviteId` and `email` as query parameters. After the user signs in or signs up, they are redirected back to the `accept-invite` page.
     - **Logged In (Wrong Email)**: If the active session email does not match the invitation's `to` field, the system blocks acceptance and displays a "Email Mismatch" error.
     - **Logged In (Correct Email)**: Immediately proceeds to the acceptance transaction.

### Phase 3: Completion (Transactional Acceptance)
The `acceptInvitation` function in `useMultiTeam.tsx` executes a **Firestore Batch Write** to ensure atomicity:
1. **Update Team Member**: Sets `businesses/{id}/team/{userId}` to `status: 'active'`, assigns the `role`, and sets `joinedAt`.
2. **Link Membership**: Adds the business to `users/{userId}/memberships/{businessId}` so the user can see it in their business switcher.
3. **Cleanup**: Deletes the source document from the top-level `invitations` collection.
4. **Final Action**: Redirects the user to the application dashboard.

---

## 4. Security Guardrails
- **Magic Link Tokenization**: Invitation IDs are cryptographically strong UUIDs/Auto-IDs, preventing brute-force access to pending invites.
- **Email Lockdown**: Even if an attacker obtains an invitation link, they cannot accept it unless they are authenticated as the specific email address the invite was sent to.
- **Role Protection**: The role is locked at the time of the invitation. The user cannot elevate their own role during the acceptance process.
- **Atomic State**: Batch writes ensure that a user never ends up in a "Half-Joined" state (e.g., being in the team list but not having the business in their switcher).

---

## 5. Developer Guide for Mobile (Flutter)
1. **Deep Linking**: Implement Firebase Dynamic Links or App Links to handle the `/accept-invite` URL.
2. **Auth Integration**: Ensure the onboarding flow captures the `inviteId` from the deep link and persists it through the login/signup process.
3. **Transactional Parity**: Use `FirebaseFirestore.instance.runTransaction()` to mirror the exact batch write logic used in the Web implementation.
