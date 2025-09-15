# Announcements Management System

## Overview
The announcements management system allows administrators to create, edit, delete, and pin announcements. It includes push notification functionality with optional crop targeting for segmented messaging.

## Features

### ✅ Implemented Features
- **CRUD Operations**: Create, read, update, and delete announcements
- **Pin Toggle**: Pin/unpin announcements to show them at the top
- **Push Notifications**: Send FCM push notifications to the "announcements" topic
- **Crop Segmentation**: Optional targeting by crop types (tomato, pepper, etc.)
- **Search & Filter**: Search announcements and filter by pinned status
- **Real-time Updates**: Live updates when announcements are modified
- **Admin UI**: Comprehensive management interface

### 🔧 Technical Implementation

#### Models
- **Announcement Model** (`lib/models/announcement.dart`)
  - Added `cropTargets` field for crop segmentation
  - Added `pushSent` field to track push notification status
  - Updated serialization methods

#### Services
- **FCM Push Service** (`lib/services/fcm_push_service.dart`)
  - Send push notifications to topics
  - Support for crop-specific topics
  - User subscription management
  - Batch messaging capabilities

#### Providers
- **Announcement Provider** (`lib/providers/announcement_provider.dart`)
  - Enhanced with push notification functionality
  - Crop target management
  - Error handling and loading states

#### UI Components
- **Announcements Page** (`lib/ui/admin/announcements_page.dart`)
  - Complete CRUD interface
  - Search and filtering
  - Pin/unpin functionality
  - Push notification controls
  - Crop target selection

## Setup Instructions

### 1. FCM Server Key Configuration

**IMPORTANT**: You need to configure the FCM server key for push notifications to work.

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings → Cloud Messaging
4. Copy the "Server key"
5. Update `lib/services/fcm_push_service.dart`:

```dart
// Replace this line:
static const String _serverKey = 'YOUR_FCM_SERVER_KEY_HERE';

// With your actual server key:
static const String _serverKey = 'AAAA...your-actual-server-key...';
```

### 2. Security Considerations

**⚠️ Security Warning**: The server key should be stored securely in production:

- **Development**: You can hardcode it temporarily
- **Production**: Use environment variables or secure configuration
- **Alternative**: Implement a backend service to handle FCM messaging

### 3. Topic Subscription

Users are automatically subscribed to announcement topics when they:
- Install the app
- Log in
- Update their crop preferences

Topics include:
- `announcements` - General announcements
- `announcements_tomato` - Tomato-specific announcements
- `announcements_pepper` - Pepper-specific announcements
- etc.

## Usage Guide

### Creating Announcements

1. Navigate to Admin → Announcements
2. Click the "+" button to create a new announcement
3. Fill in:
   - **Title**: Announcement title
   - **Message**: Announcement content
   - **Pin**: Check to pin at the top
   - **Send Push**: Check to send push notification immediately
   - **Target Crops**: Select specific crops (optional)

### Managing Announcements

- **Search**: Use the search bar to find specific announcements
- **Filter**: Use "Pinned Only" filter to show only pinned announcements
- **Actions**: Use the menu (⋮) on each announcement for:
  - Pin/Unpin
  - Send Push Notification
  - Edit
  - Delete

### Push Notifications

- **Immediate**: Send when creating new announcements
- **Delayed**: Send push notifications for existing announcements
- **Segmented**: Target specific crop types
- **General**: Send to all users subscribed to announcements

## API Reference

### AnnouncementProvider Methods

```dart
// Create announcement with push notification
await provider.createAnnouncement(
  title: 'New Feature',
  body: 'Check out our latest update!',
  createdBy: 'admin@example.com',
  pinned: true,
  cropTargets: ['tomato', 'pepper'],
  sendPush: true,
);

// Toggle pin status
await provider.togglePin(announcementId);

// Send push notification for existing announcement
await provider.sendPushNotification(announcementId);

// Get available crop targets
final crops = await provider.getAvailableCropTargets();
```

### FCMPushService Methods

```dart
// Send to general announcements topic
await pushService.sendToTopic(
  topic: 'announcements',
  title: 'New Announcement',
  body: 'Important update for all users',
);

// Send with crop targeting
await pushService.sendAnnouncementPush(
  title: 'Tomato Growing Tips',
  body: 'New techniques for better yields',
  cropTargets: ['tomato'],
);

// Subscribe user to topics
await pushService.subscribeUserToAnnouncements(
  userId,
  cropTargets: ['tomato', 'pepper'],
);
```

## Troubleshooting

### Push Notifications Not Working

1. **Check Server Key**: Ensure FCM server key is correctly configured
2. **Check Permissions**: Verify notification permissions are granted
3. **Check Topics**: Ensure users are subscribed to announcement topics
4. **Check Network**: Verify internet connectivity
5. **Check Logs**: Look for error messages in console

### Common Issues

- **"Failed to send FCM message"**: Check server key and network
- **"No FCM tokens found"**: Users need to be logged in and have granted permissions
- **"Topic subscription failed"**: Check Firebase project configuration

## Future Enhancements

- [ ] Scheduled announcements
- [ ] Rich media attachments
- [ ] User engagement analytics
- [ ] A/B testing for announcements
- [ ] Multi-language support
- [ ] Announcement templates
- [ ] User preference management
- [ ] Delivery status tracking

## Dependencies Added

- `http: ^1.2.2` - For FCM HTTP API calls

## Files Modified/Created

### New Files
- `lib/services/fcm_push_service.dart`
- `lib/ui/admin/README_ANNOUNCEMENTS.md`

### Modified Files
- `lib/models/announcement.dart` - Added crop targeting and push status
- `lib/providers/announcement_provider.dart` - Enhanced with push functionality
- `lib/ui/admin/announcements_page.dart` - Complete rewrite with full functionality
- `lib/services/notification_service.dart` - Added showNotification method
- `lib/app.dart` - Added FCM push service provider
- `pubspec.yaml` - Added http dependency
