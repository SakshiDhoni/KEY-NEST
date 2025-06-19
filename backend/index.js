
require('dotenv').config();
console.log("🔹 Starting server...");

const express = require('express');
console.log("✅ Express loaded");

const admin = require('firebase-admin');
console.log("✅ Firebase Admin loaded");

const cors = require('cors');
const twilio = require('twilio');
console.log("✅ Environment variables loaded");

// Firebase service account
const serviceAccount = require('./serviceAccountKey.json');
console.log("✅ Service account loaded");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
console.log("✅ Firebase initialized");

const app = express();
app.use(cors());
app.use(express.json());

const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);
const twilioFrom = process.env.TWILIO_NUMBER;

const nodemailer = require('nodemailer');  
// Nodemailer transporter for email
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello from Backend!' });
});
// Add this before app.listen
app.post('/api/register', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  try {
    const user = await admin.auth().createUser({
      email,
      password,
    });
    console.log("✅ Firebase user created:", user.uid);
    res.status(200).json({ message: 'User registered', uid: user.uid });
  } catch (error) {
    console.error("❌ Error creating user:", error.message);
    res.status(500).json({ error: error.message });
  }
});


app.post('/api/notify', async (req, res) => {
  const { to, text, channel } = req.body;

  if (!to || !text || !channel) {
    return res.status(400).json({ error: 'to, text, and channel are required' });
  }

  try {
    if (channel === 'sms' || channel === 'whatsapp') {
      const prefix = channel === 'whatsapp' ? 'whatsapp:' : '';
      const formattedTo = to.startsWith('whatsapp:') ? to : prefix + to;
      const message = await client.messages.create({
        body: text,
        from: prefix + twilioFrom,
        to: formattedTo,
      });
      console.log(`✅ ${channel.toUpperCase()} sent:`, message.sid);
    }

    if (channel === 'email') {
      const mailOptions = {
        from: process.env.SMTP_USER,
        to,
        subject: 'Welcome to CtoC Broker!',
        text,
      };

      const info = await transporter.sendMail(mailOptions);
      console.log(`✅ Email sent:`, info.messageId);
    }

    return res.json({ status: 'Notifications sent successfully' });
  } catch (err) {
    console.error('❌ Notify error:', err.message);
    return res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend listening on http://localhost:${PORT}`);
});
