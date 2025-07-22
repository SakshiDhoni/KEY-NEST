// index.js
require('dotenv').config();
console.log("🔹 Starting server...");

const express     = require('express');
const cors        = require('cors');
const multer      = require('multer');
const admin       = require('firebase-admin');
const twilio      = require('twilio');
const nodemailer  = require('nodemailer');
const cloudinary  = require('cloudinary').v2;
const streamifier = require('streamifier');

// ——— Firebase Admin Init ———
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
console.log("✅ Firebase initialized");

// ——— Cloudinary Config ———
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key:    process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});
console.log("✅ Cloudinary configured");

// ——— Express Setup ———
const app = express();
app.use(cors());
app.use(express.json());

// ——— Multer Setup ———
const upload = multer({ storage: multer.memoryStorage() }).any();

// ——— Twilio & Nodemailer Setup ———
const client     = twilio(process.env.TWILIO_SID, process.env.TWILIO_TOKEN);
const twilioFrom = process.env.TWILIO_NUMBER;
const transporter = nodemailer.createTransport({
  host:   process.env.SMTP_HOST,
  port:   +process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth:   { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

// ——— Helper to upload buffer to Cloudinary ———
function streamUpload(buffer) {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: 'contractor_properties' },
      (err, result) => err ? reject(err) : resolve(result.secure_url)
    );
    streamifier.createReadStream(buffer).pipe(uploadStream);
  });
}

// ——— Endpoints ———

// Hello
app.get('/api/hello', (req, res) => res.json({ message: 'Hello from Backend!' }));

// Enhanced Register with username
app.post('/api/register', async (req, res) => {
  const { email, password, username } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }
  
  if (!username) {
    return res.status(400).json({ error: 'Username is required' });
  }

  try {
    // Check if username already exists
    const usernameCheck = await db.collection('users')
      .where('username', '==', username)
      .get();
    
    if (!usernameCheck.empty) {
      return res.status(400).json({ error: 'Username already exists' });
    }

    // Create Firebase Auth user
    const user = await admin.auth().createUser({ 
      email, 
      password,
      displayName: username 
    });
    
    // Store user data in Firestore
    await db.collection('users').doc(user.uid).set({
      uid: user.uid,
      email: email,
      username: username,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
      isActive: true
    });

    console.log("✅ Firebase user created:", user.uid);
    res.json({ 
      message: 'User registered successfully', 
      uid: user.uid,
      username: username 
    });
  } catch (e) {
    console.error("❌ Error creating user:", e.message);
    res.status(500).json({ error: e.message });
  }
});

// Notify
app.post('/api/notify', async (req, res) => {
  const { to, text, channel } = req.body;
  if (!to || !text || !channel) return res.status(400).json({ error: 'to, text, and channel are required' });
  try {
    if (channel === 'sms' || channel === 'whatsapp') {
      const prefix = channel === 'whatsapp' ? 'whatsapp:' : '';
      const msgTo = to.startsWith('whatsapp:') ? to : prefix + to;
      const m = await client.messages.create({ body: text, from: prefix + twilioFrom, to: msgTo });
      console.log(`✅ ${channel} sent:`, m.sid);
    }
    if (channel === 'email') {
      const info = await transporter.sendMail({ from: process.env.SMTP_USER, to, subject: 'Welcome!', text });
      console.log('✅ Email sent:', info.messageId);
    }
    res.json({ status: 'Notifications sent' });
  } catch (e) {
    console.error('❌ Notify error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// ——— Contractor Property (multiple images) ———
app.post('/api/contractor_property', upload, async (req, res) => {
  try {
    console.log('▶️ All parts received:', req.files?.map(f => f.fieldname));

    const imageFiles = (req.files || []).filter(f => f.fieldname === 'images');
    console.log('▶️ imageFiles count:', imageFiles.length);

    const {
      name,
      location,
      amount,
      contractorName = '',
      contractorPhone = '',
      vacancies = '',
      discount = ''
    } = req.body;

    if (!name || !location || !amount) {
      return res.status(400).json({ error: 'name, location, and amount are required' });
    }

    const imageUrls = [];
    for (const file of imageFiles) {
      const url = await streamUpload(file.buffer);
      imageUrls.push(url);
    }

    const newProperty = {
      name,
      location,
      amount: Number(amount),
      contractorName,
      contractorPhone,
      vacancies: vacancies ? Number(vacancies) : '',
      discount,
      imageUrls,
      isBooked: false, // Add default booking status
      bookedBy: null,
      bookedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection('contractor_properties').add(newProperty);
    newProperty.id = docRef.id;

    res.status(201).json({ success: true, data: newProperty });

  } catch (e) {
    console.error('❌ /api/contractor_property error:', e);
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/contractor/addCar', upload, async (req, res) => {
  try {
    console.log('▶️ Car form submission received');

    const imageFiles = (req.files || []).filter(f => f.fieldname === 'images');
    console.log('▶️ Car image files count:', imageFiles.length);

    const {
      brand,
      model,
      showroom,
      location,
      price,
      discount = ''
    } = req.body;

    if (!brand || !model || !showroom || !location || !price) {
      return res.status(400).json({ error: 'All fields except discount are required' });
    }

    const imageUrls = [];
    for (const file of imageFiles) {
      const url = await streamUpload(file.buffer);
      imageUrls.push(url);
    }

    const newCar = {
      brand,
      model,
      showroom,
      location,
      price: Number(price),
      discount,
      imageUrls,
      isBooked: false, // Add default booking status
      bookedBy: null,
      bookedAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const docRef = await db.collection('contractor_cars').add(newCar);
    newCar.id = docRef.id;

    res.status(201).json({ success: true, data: newCar });

  } catch (e) {
    console.error('❌ /api/contractor/addCar error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Enhanced Book Item endpoint (supports both properties and cars)
app.post('/api/book-item', async (req, res) => {
  try {
    const { 
      userEmail,
      username,
      itemId, 
      itemType, // 'property' or 'car'
      itemName,
      itemLocation,
      amount,
      paymentMethod,
    } = req.body;

    if (!userEmail || !itemId || !itemType || !amount) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if item is already booked
    const existingBooking = await db.collection('booked_items')
      .where('itemId', '==', itemId)
      .where('itemType', '==', itemType)
      .get();

    if (!existingBooking.empty) {
      return res.status(400).json({ error: 'Item already booked' });
    }

    // Create booking record
    const bookingData = {
      userEmail,
      username,
      itemId,
      itemType,
      itemName: itemName || 'Unknown Item',
      itemLocation: itemLocation || 'Unknown Location',
      amount: Number(amount),
      paymentMethod: paymentMethod || 'UPI',
      bookingDate: admin.firestore.FieldValue.serverTimestamp(),
      paymentStatus: 'completed',
      bookingStatus: 'confirmed',
      transactionId: `TXN_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };

    const bookingRef = await db.collection('booked_items').add(bookingData);

    // Update item availability
    const collection = itemType === 'property' ? 'contractor_properties' : 'contractor_cars';
    await db.collection(collection).doc(itemId).update({
      isBooked: true,
      bookedBy: userEmail,
      bookedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`✅ ${itemType} booked:`, bookingRef.id);
    res.status(201).json({ 
      success: true, 
      bookingId: bookingRef.id,
      transactionId: bookingData.transactionId,
      message: `${itemType} booked successfully` 
    });
  } catch (e) {
    console.error('❌ Book item error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// Get user's booked items (both properties and cars)
app.get('/api/booked-items/:userEmail', async (req, res) => {
  try {
    const { userEmail } = req.params;
    
    const bookingsSnap = await db.collection('booked_items')
      .where('userEmail', '==', userEmail)
      .orderBy('bookingDate', 'desc')
      .get();

    const bookedItems = [];
    
    for (const doc of bookingsSnap.docs) {
      const booking = doc.data();
      
      // Get the actual item details
      const collection = booking.itemType === 'property' ? 'contractor_properties' : 'contractor_cars';
      const itemDoc = await db.collection(collection).doc(booking.itemId).get();
      
      if (itemDoc.exists) {
        const itemData = itemDoc.data();
        bookedItems.push({
          id: doc.id,
          ...booking,
          // Include item details for display
          name: itemData.name,
          brand: itemData.brand,
          model: itemData.model,
          location: itemData.location,
          amount: itemData.amount || itemData.price,
          imageUrls: itemData.imageUrls || []
        });
      }
    }

    res.json({ bookedItems });
  } catch (e) {
    console.error('❌ Get booked items error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// Enhanced Get Properties (filter out booked ones in memory)
app.get('/api/properties', async (req, res) => {
  try {
    const { location, name, includeBooked = 'false' } = req.query;
    let query = db.collection('contractor_properties');
    
    // Apply basic filters
    if (location) {
      query = query.where('location', '==', location);
    }
    if (name) {
      query = query.where('name', '==', name);
    }
    
    // Order by creation date
    query = query.orderBy('createdAt', 'desc');
    
    const snap = await query.get();
    let results = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    // Filter out booked properties in memory if not specifically requested
    if (includeBooked !== 'true') {
      results = results.filter(property => !property.isBooked);
    }
    
    console.log(`✅ Properties fetched: ${results.length} available properties`);
    res.json({ properties: results });
  } catch (e) {
    console.error('❌ GET /api/properties', e);
    res.status(500).json({ error: e.message });
  }
});

// Enhanced Get Cars (filter out booked ones in memory)
app.get('/api/cars', async (req, res) => {
  try {
    const { model, location, includeBooked = 'false' } = req.query;
    let query = db.collection('contractor_cars');
    
    // Apply basic filters
    if (location) {
      query = query.where('location', '==', location);
    }
    if (model) {
      query = query.where('model', '==', model);
    }
    
    // Order by creation date
    query = query.orderBy('createdAt', 'desc');
    
    const snap = await query.get();
    let results = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    // Filter out booked cars in memory if not specifically requested
    if (includeBooked !== 'true') {
      results = results.filter(car => !car.isBooked);
    }
    
    console.log(`✅ Cars fetched: ${results.length} available cars`);
    res.json({ cars: results });
  } catch (e) {
    console.error('❌ GET /api/cars', e);
    res.status(500).json({ error: e.message });
  }
});

// Get contractor's properties
app.get('/api/contractor/properties/:contractorEmail', async (req, res) => {
  try {
    const { contractorEmail } = req.params;
    
    const snap = await db.collection('contractor_properties')
      .where('contractorEmail', '==', contractorEmail)
      .orderBy('createdAt', 'desc')
      .get();
    
    const properties = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    res.json({ properties });
  } catch (e) {
    console.error('❌ Get contractor properties error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

// Get contractor's cars
app.get('/api/contractor/cars/:contractorEmail', async (req, res) => {
  try {
    const { contractorEmail } = req.params;
    
    const snap = await db.collection('contractor_cars')
      .where('contractorEmail', '==', contractorEmail)
      .orderBy('createdAt', 'desc')
      .get();
    
    const cars = snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    
    res.json({ cars });
  } catch (e) {
    console.error('❌ Get contractor cars error:', e.message);
    res.status(500).json({ error: e.message });
  }
});


// Start server
const PORT = process.env.PORT || 3000;
app.get('/', (req, res) =>
  res.send('CtoC Broker backend running with enhanced authentication and booking system'));
app.listen(PORT, () => console.log(`🚀 Backend listening on http://localhost:${PORT}`));
