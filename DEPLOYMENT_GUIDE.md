# AgriMix Cloud Functions - Deployment Guide

## Quick Setup for Email Notifications

### Step 1: Configure Email Settings

**Option A: Gmail (Easiest for testing)**
1. Go to your Gmail account
2. Enable 2-Factor Authentication
3. Generate an "App Password" (not your regular password)
4. Set environment variables:

```bash
# Set environment variables for deployment
firebase functions:config:set email.user="your-email@gmail.com" email.password="your-app-password"
```

**Option B: SendGrid (Recommended for production)**
1. Create a SendGrid account
2. Generate an API key
3. Set environment variables:

```bash
firebase functions:config:set email.user="apikey" email.password="your-sendgrid-api-key"
```

### Step 2: Deploy Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build functions
npm run build

# Deploy to Firebase
firebase deploy --only functions
```

### Step 3: Test Email Notifications

1. Go to Firebase Console → Firestore
2. Find a user document in the `users` collection
3. Change `approved` field from `false` to `true`
4. Check if email is received

## Troubleshooting

### Email Not Sending?
- Check Firebase Console → Functions → Logs
- Verify email credentials are correct
- Make sure user has a valid email address in Firestore

### Function Not Triggering?
- Check Firestore security rules
- Verify the document path is `users/{userId}`
- Check function logs in Firebase Console

### Gmail Issues?
- Make sure you're using an "App Password", not your regular password
- Enable "Less secure app access" if needed
- Check Gmail's security settings

## Current Status
✅ Cloud Functions code is ready
✅ TypeScript compilation successful
⏳ Email configuration needed
⏳ Functions deployment needed
