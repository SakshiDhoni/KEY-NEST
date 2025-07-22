import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'new_pages/welcome_page.dart';
import 'new_pages/contractor_property_form.dart';
import 'new_pages/contractor_car_form.dart';
import 'new_pages/customer_dashboard.dart';

// If you used `flutterfire configure`, import your generated firebase_options.dart here instead:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase. If you generated firebase_options.dart, use that instead.
  await Firebase.initializeApp(
    options: const FirebaseOptions(
     apiKey: "AIzaSyC4QfcD-VEQc2NxifFHjKXaGGCR8rGDbKI",
  authDomain: "ctoc-broker-web.firebaseapp.com",
  projectId: "ctoc-broker-web",
  storageBucket: "ctoc-broker-web.firebasestorage.app",
  messagingSenderId: "1088072759677",
  appId: "1:1088072759677:web:92553036490b517cb37414",
  measurementId: "G-L1NX20JEQN"
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broker Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      // Define routes for navigation
      routes: {
        '/' : (context) => const WelcomeScreen(),
      },
      initialRoute: '/',
    );
  }
}
