import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';
import { Change, EventContext } from 'firebase-functions';
import { DocumentSnapshot } from 'firebase-functions/v1/firestore';

// Initialize Firebase Admin
admin.initializeApp();

// Create nodemailer transporter
// You can use Gmail, SendGrid, or any SMTP provider
const transporter = nodemailer.createTransport({
  service: 'gmail', // or use your preferred email service
  auth: {
    user: functions.config().email?.user || 'your-email@gmail.com',
    pass: functions.config().email?.password || 'your-app-password'
  }
});

// Function to send approval email
export const sendApprovalEmail = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change: Change<DocumentSnapshot>, context: EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    // Check if data exists
    if (!before || !after) {
      console.error('Missing document data');
      return null;
    }

    // Check if user was just approved (approved changed from false to true)
    if (!before.approved && after.approved) {
      const userEmail = after.email;
      const userName = after.name || after.firstName || 'User';

      if (!userEmail) {
        console.error('No email found for user:', userId);
        return null;
      }

      const mailOptions = {
        from: functions.config().email?.user || 'your-email@gmail.com',
        to: userEmail,
        subject: '🎉 Welcome to AgriMix - Your Account Has Been Approved!',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #2E7D32; margin-bottom: 10px;">🎉 Congratulations!</h1>
              <h2 style="color: #333; margin-bottom: 20px;">Your AgriMix Account Has Been Approved</h2>
            </div>
            
            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
              <p style="font-size: 16px; color: #333; margin-bottom: 15px;">
                Hello <strong>${userName}</strong>,
              </p>
              <p style="font-size: 16px; color: #333; margin-bottom: 15px;">
                Great news! Your account registration has been reviewed and approved by our admin team. 
                You can now access all features of the AgriMix application.
              </p>
            </div>

            <div style="background-color: #E8F5E8; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
              <h3 style="color: #2E7D32; margin-bottom: 15px;">What's Next?</h3>
              <ul style="color: #333; line-height: 1.6;">
                <li>📱 Open the AgriMix app on your device</li>
                <li>🔐 Log in with your registered credentials</li>
                <li>🌱 Start exploring fermentation recipes and community features</li>
                <li>📊 Track your fermentation processes</li>
                <li>👥 Connect with other fermentation enthusiasts</li>
              </ul>
            </div>

            <div style="text-align: center; margin: 30px 0;">
              <a href="https://play.google.com/store/apps/details?id=com.agrimix.app" 
                 style="background-color: #2E7D32; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
                Download AgriMix App
              </a>
            </div>

            <div style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 30px;">
              <p style="font-size: 14px; color: #666; text-align: center;">
                If you have any questions or need assistance, please don't hesitate to contact our support team.
              </p>
              <p style="font-size: 14px; color: #666; text-align: center; margin-top: 10px;">
                Welcome to the AgriMix community! 🌱
              </p>
            </div>
          </div>
        `
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log('Approval email sent successfully to:', userEmail);
        
        // Optional: Add a notification document to Firestore
        await admin.firestore().collection('users').doc(userId).collection('notifications').add({
          type: 'approval',
          title: 'Account Approved',
          message: 'Your account has been approved! You can now access all features.',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false
        });

        return null;
      } catch (error) {
        console.error('Error sending approval email:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send approval email');
      }
    }

    return null;
  });

// Optional: Function to send rejection email
export const sendRejectionEmail = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change: Change<DocumentSnapshot>, context: EventContext) => {
    const before = change.before.data();
    const after = change.after.data();
    const userId = context.params.userId;

    // Check if data exists
    if (!before || !after) {
      console.error('Missing document data');
      return null;
    }

    // Check if user was just rejected (approved changed from true to false or status changed to rejected)
    if ((before.approved && !after.approved) || after.status === 'rejected') {
      const userEmail = after.email;
      const userName = after.name || after.firstName || 'User';
      const rejectionReason = after.rejectionReason || 'Your application did not meet our current requirements.';

      if (!userEmail) {
        console.error('No email found for user:', userId);
        return null;
      }

      const mailOptions = {
        from: functions.config().email?.user || 'your-email@gmail.com',
        to: userEmail,
        subject: 'AgriMix Account Application Update',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <div style="text-align: center; margin-bottom: 30px;">
              <h1 style="color: #D32F2F; margin-bottom: 10px;">Account Application Update</h1>
            </div>
            
            <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
              <p style="font-size: 16px; color: #333; margin-bottom: 15px;">
                Hello <strong>${userName}</strong>,
              </p>
              <p style="font-size: 16px; color: #333; margin-bottom: 15px;">
                Thank you for your interest in joining AgriMix. After careful review, 
                we regret to inform you that your account application has not been approved at this time.
              </p>
              <p style="font-size: 16px; color: #333; margin-bottom: 15px;">
                <strong>Reason:</strong> ${rejectionReason}
              </p>
            </div>

            <div style="background-color: #FFF3E0; padding: 20px; border-radius: 8px; margin-bottom: 20px;">
              <h3 style="color: #F57C00; margin-bottom: 15px;">What You Can Do</h3>
              <ul style="color: #333; line-height: 1.6;">
                <li>📝 Review your application and ensure all information is complete and accurate</li>
                <li>🔄 You may reapply after addressing any issues mentioned</li>
                <li>📞 Contact our support team if you have questions about the decision</li>
                <li>📚 Learn more about our community guidelines and requirements</li>
              </ul>
            </div>

            <div style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 30px;">
              <p style="font-size: 14px; color: #666; text-align: center;">
                We appreciate your interest in AgriMix and hope to welcome you to our community in the future.
              </p>
            </div>
          </div>
        `
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log('Rejection email sent successfully to:', userEmail);
        return null;
      } catch (error) {
        console.error('Error sending rejection email:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send rejection email');
      }
    }

    return null;
  });
