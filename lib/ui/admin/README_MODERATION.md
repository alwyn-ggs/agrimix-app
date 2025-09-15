# Community Moderation System

This document describes the community moderation system implemented for the AgriMix app.

## Overview

The moderation system allows administrators to:
- View a queue of reported content (posts, comments, recipes, users)
- Take moderation actions: dismiss, warn user, delete content, or temporarily ban users
- Send notifications to affected users
- Track all actions for moderation

## Components

### 1. Models

#### Violation Model (`lib/models/violation.dart`)
Enhanced violation model with:
- Support for different target types (post, comment, recipe, user)
- Multiple statuses (open, resolved, dismissed)
- Action tracking (dismiss, warn, delete, ban)
- Ban expiration dates
- Reporter and admin tracking

### 2. Providers

#### ModerationProvider (`lib/providers/moderation_provider.dart`)
Main provider for moderation functionality:
- Real-time violation monitoring
- Moderation action execution
- User notification sending
- Statistics tracking

### 3. UI Components

#### ModerationQueuePage (`lib/ui/admin/moderation_queue_page.dart`)
Main moderation interface with:
- Tabbed view (Open, Resolved, Dismissed violations)
- Violation cards with details
- Action buttons for each violation
- Status indicators

#### ModerationActionDialog (`lib/ui/admin/moderation_action_dialog.dart`)
Dialog for taking moderation actions:
- Action selection (warn, delete, ban)
- Reason input
- Ban duration slider
- Confirmation and execution

#### ReportDialog (`lib/ui/community/report_dialog.dart`)
User-facing report dialog:
- Predefined report reasons
- Custom reason input
- Content information display

#### ReportButton (`lib/ui/community/report_button.dart`)
Reusable report button component:
- Compact and full button styles
- Easy integration into existing UI

### 4. Services

#### NotificationService (`lib/services/notification_service.dart`)
Handles user notifications:
- Moderation action notifications
- Violation report notifications to admins
- Notification management (read/unread)

#### AuditService (`lib/services/audit_service.dart`)
Enhanced with moderation logging:
- Violation moderation actions
- User warnings
- Content deletions
- User bans

## Usage

### 1. Setting up the ModerationProvider

```dart
// In your main app setup
final moderationProvider = ModerationProvider(
  violationsRepo,
  postsRepo,
  commentsRepo,
  usersRepo,
  auditService,
  messagingService,
  notificationService,
);

// Add to MultiProvider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => moderationProvider),
    // ... other providers
  ],
  child: MyApp(),
)
```

### 2. Adding Report Buttons to Content

```dart
// In a post widget
ReportButton(
  targetType: ViolationTargetType.post,
  targetId: post.id,
  targetTitle: post.title,
  penalizedUserUid: post.ownerUid,
  isCompact: true, // For icon-only button
)

// In a comment widget
ReportButton(
  targetType: ViolationTargetType.comment,
  targetId: comment.id,
  penalizedUserUid: comment.authorId,
)
```

### 3. Accessing Moderation Queue

```dart
// Navigate to moderation page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ModerationQueuePage(),
  ),
);
```

### 4. Reporting Violations Programmatically

```dart
// Report a violation
await context.read<ModerationProvider>().reportViolationAndNotify(
  targetType: ViolationTargetType.post,
  targetId: postId,
  reason: 'Inappropriate content',
  reporterUid: currentUserId,
  penalizedUserUid: postOwnerId,
);
```

## Moderation Actions

### 1. Dismiss
- Marks violation as dismissed
- No action taken against user
- Logged in audit trail

### 2. Warn User
- Sends warning notification to user
- Marks violation as resolved
- Logged in audit trail

### 3. Delete Content
- Removes the reported content
- Sends notification to user
- Marks violation as resolved
- Logged in audit trail

### 4. Temporary Ban
- Suspends user account for specified duration
- Sends notification with ban details
- Marks violation as resolved
- Logged in audit trail

## Notifications

The system sends notifications for:
- User warnings
- Content deletions
- Account suspensions
- New violation reports (to admins)

Notifications are stored in the user's notification collection and can be displayed in the app.

## Action Tracking

All moderation actions are logged with:
- Admin ID
- Action taken
- Target details
- Reason
- Timestamp
- Metadata

## Database Structure

### Violations Collection
```json
{
  "id": "violation_id",
  "targetType": "post|comment|recipe|user",
  "targetId": "target_id",
  "reason": "report_reason",
  "status": "open|resolved|dismissed",
  "penalizedUserUid": "user_id",
  "reporterUid": "reporter_id",
  "adminId": "admin_id",
  "actionTaken": "dismiss|warn|delete|ban",
  "actionReason": "action_reason",
  "banExpiresAt": "timestamp",
  "createdAt": "timestamp",
  "resolvedAt": "timestamp"
}
```

### User Notifications Collection
```json
{
  "title": "notification_title",
  "body": "notification_body",
  "type": "warning|content_removed|account_suspended|violation_report",
  "data": {},
  "read": false,
  "createdAt": "timestamp"
}
```

## Security Considerations

1. **Admin-only access**: Moderation features should only be accessible to users with admin role
2. **Input validation**: All user inputs should be validated
3. **Rate limiting**: Consider implementing rate limiting for reports
4. **Action tracking**: All actions are tracked for accountability
5. **User privacy**: Respect user privacy when handling reports

## Future Enhancements

1. **Automated moderation**: AI-powered content filtering
2. **Appeal system**: Allow users to appeal moderation actions
3. **Moderation guidelines**: Built-in guidelines for moderators
4. **Bulk actions**: Handle multiple violations at once
5. **Analytics**: Detailed moderation statistics and trends
