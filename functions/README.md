# AgriMix Cloud Functions - Email Notifications

This directory contains Firebase Cloud Functions for sending email notifications when users get approved or rejected.

## Setup Instructions

### 1. Install Dependencies
```bash
cd functions
npm install
```

### 2. Configure Email Settings
You need to set up email configuration using Firebase Functions config:

#### Option A: Gmail (Recommended for testing)
```bash
firebase functions:config:set email.user="your-email@gmail.com" email.password="your-app-password"
```

**Note:** For Gmail, you need to:
1. Enable 2-factor authentication
2. Generate an "App Password" (not your regular password)
3. Use the app password in the config

#### Option B: SendGrid (Recommended for production)
```bash
firebase functions:config:set email.user="apikey" email.password="your-sendgrid-api-key"
```

Then update the transporter configuration in `src/index.ts`:
```typescript
const transporter = nodemailer.createTransporter({
  service: 'sendgrid',
  auth: {
    user: 'apikey',
    pass: functions.config().email?.password
  }
});
```

#### Option C: Custom SMTP
```bash
firebase functions:config:set email.user="your-smtp-username" email.password="your-smtp-password" email.host="smtp.your-provider.com" email.port="587"
```

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

## How It Works

### User Approval Flow
1. Admin changes `users/{userId}.approved` from `false` to `true`
2. Cloud Function triggers automatically
3. Email is sent to user's registered email address
4. Optional: Notification document is added to `users/{userId}/notifications`

### User Rejection Flow
1. Admin changes `users/{userId}.approved` from `true` to `false` OR sets `status` to `rejected`
2. Cloud Function triggers automatically
3. Rejection email is sent with reason (if provided)

## Email Templates

The functions include:
- **Approval Email**: Welcome message with next steps
- **Rejection Email**: Professional rejection with guidance

Both emails are HTML-formatted and mobile-friendly.

## Testing

### Test Locally
```bash
npm run serve
```

### Test in Production
1. Create a test user in Firestore
2. Change `approved` field from `false` to `true`
3. Check email delivery

## Monitoring

View function logs:
```bash
firebase functions:log
```

## Security Notes

- Email credentials are stored securely in Firebase Functions config
- Functions only trigger on actual document changes
- Error handling prevents function failures from affecting user experience

## Customization

You can customize:
- Email templates in `src/index.ts`
- Email service provider
- Notification content
- Additional triggers (e.g., status changes)

## Troubleshooting

### Common Issues
1. **Email not sending**: Check credentials and SMTP settings
2. **Function not triggering**: Verify Firestore rules and document structure
3. **Permission errors**: Ensure Firebase project has proper permissions

### Debug Commands
```bash
# View function logs
firebase functions:log --only sendApprovalEmail

# Test function locally
firebase functions:shell
```
