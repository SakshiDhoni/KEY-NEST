require('dotenv').config();
console.log("🔹 Starting server...");

const express = require('express');
console.log("✅ Express loaded");

const admin = require('firebase-admin');
console.log("✅ Firebase Admin loaded");

const cors = require('cors');
const twilio = require('twilio');
console.log("✅ Environment variables loaded");

const multer = require('multer');
console.log("✅ Multer loaded");

// Firebase service account
const serviceAccount = require('./serviceAccountKey.json');
console.log("✅ Service account loaded");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET
});
console.log("✅ Firebase initialized");

// Get Firestore database
const db = admin.firestore();
const bucket = admin.storage().bucket();
console.log("✅ Firestore & Storage initialized");

const app = express();
app.use(cors());
app.use(express.json());

const upload = multer({ storage: multer.memoryStorage() });

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

// User registration endpoint
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

// Notification endpoint
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

// ========== NEW FIREBASE ENDPOINTS ==========

// Get all user inquiries
app.get('/api/inquiries', async (req, res) => {
  try {
    const snapshot = await db.collection('user_inquiries')
      .orderBy('timestamp', 'desc')
      .get();
    
    const inquiries = [];
    snapshot.forEach(doc => {
      inquiries.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json({ inquiries });
  } catch (error) {
    console.error('❌ Error fetching inquiries:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get inquiries by category (Properties or Cars)
app.get('/api/inquiries/category/:category', async (req, res) => {
  try {
    const { category } = req.params;
    const snapshot = await db.collection('user_inquiries')
      .where('category', '==', category)
      .orderBy('timestamp', 'desc')
      .get();
    
    const inquiries = [];
    snapshot.forEach(doc => {
      inquiries.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json({ inquiries, category });
  } catch (error) {
    console.error('❌ Error fetching inquiries by category:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get inquiries by city
app.get('/api/inquiries/city/:city', async (req, res) => {
  try {
    const { city } = req.params;
    const snapshot = await db.collection('user_inquiries')
      .where('city', '==', city)
      .orderBy('timestamp', 'desc')
      .get();
    
    const inquiries = [];
    snapshot.forEach(doc => {
      inquiries.push({
        id: doc.id,
        ...doc.data()
      });
    });
    
    res.json({ inquiries, city });
  } catch (error) {
    console.error('❌ Error fetching inquiries by city:', error);
    res.status(500).json({ error: error.message });
  }
});

// Add new inquiry (in case you want to add from backend)
app.post('/api/inquiries', async (req, res) => {
  try {
    const {
      contact,
      city,
      category,
      propertyType,
      carBrand,
      userType,
      contactType
    } = req.body;

    if (!contact || !city || !category) {
      return res.status(400).json({ 
        error: 'contact, city, and category are required' 
      });
    }

    const inquiryData = {
      contact,
      city,
      category,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: new Date().toISOString(),
      contactType: contactType || (contact.includes('@') ? 'email' : 'phone')
    };

    // Add category-specific data
    if (category === 'Properties') {
      inquiryData.propertyType = propertyType;
      inquiryData.userType = userType;
    } else if (category === 'Cars') {
      inquiryData.carBrand = carBrand;
    }

    const docRef = await db.collection('user_inquiries').add(inquiryData);
    
    res.status(201).json({ 
      message: 'Inquiry created successfully',
      id: docRef.id 
    });
  } catch (error) {
    console.error('❌ Error creating inquiry:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get inquiry statistics
app.get('/api/inquiries/stats', async (req, res) => {
  try {
    const snapshot = await db.collection('user_inquiries').get();
    
    let totalInquiries = 0;
    let propertiesCount = 0;
    let carsCount = 0;
    let cityStats = {};
    let contactTypeStats = { email: 0, phone: 0 };

    snapshot.forEach(doc => {
      const data = doc.data();
      totalInquiries++;
      
      if (data.category === 'Properties') propertiesCount++;
      if (data.category === 'Cars') carsCount++;
      
      // City stats
      cityStats[data.city] = (cityStats[data.city] || 0) + 1;
      
      // Contact type stats
      if (data.contactType === 'email') contactTypeStats.email++;
      else contactTypeStats.phone++;
    });

    res.json({
      totalInquiries,
      categoryStats: {
        Properties: propertiesCount,
        Cars: carsCount
      },
      cityStats,
      contactTypeStats
    });
  } catch (error) {
    console.error('❌ Error fetching stats:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete inquiry (optional)
app.delete('/api/inquiries/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.collection('user_inquiries').doc(id).delete();
    res.json({ message: 'Inquiry deleted successfully' });
  } catch (error) {
    console.error('❌ Error deleting inquiry:', error);
    res.status(500).json({ error: error.message });
  }
});

// 🔧 NEW BLOCK END
app.post('/api/contractor_property', upload.single('image'), async (req, res) => {

  // diagnostics: dump headers/body/file
    console.log('▶️ content-type:', req.headers['content-type']);
    console.log('▶️ body:', req.body);
    console.log('▶️ file:', req.file && req.file.originalname);
    
  const {
    name,
    location,
    amount,
    contractorName,
    contractorPhone,
    vacancies,
    discount,
  } = req.body;

  // Only require essential fields now
  if (!name || !location || !amount) {
    return res
      .status(400)
      .json({ error: 'Missing required fields: name, location, amount' });
  }

      try {
      let imageUrl = '';
      if (req.file) {
        // give file a unique path
        const fileName = `contractor_properties/${Date.now()}_${req.file.originalname}`;
        const file = bucket.file(fileName);

        // upload buffer to storage
        await file.save(req.file.buffer, {
          metadata: { contentType: req.file.mimetype },
          public: true,
        });

        // build public URL
        imageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
      }

      const newContractorProperty = {
        name,
        location,
        amount: Number(amount),
        contractorName: contractorName || "",
        contractorPhone: contractorPhone || "",
        vacancies: vacancies ? Number(vacancies) : "",
        discount: discount || "",
        imageUrl,  // store the URL or empty string
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const docRef = await db
        .collection('contractor_property')
        .add(newContractorProperty);

      res.status(201).json({
        message: 'Contractor property added',
        id: docRef.id
      });

    } catch (error) {
      console.error('❌ Error adding contractor property:', error);
      res.status(500).json({ error: error.message });
    }
  }
);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend listening on http://localhost:${PORT}`);
});