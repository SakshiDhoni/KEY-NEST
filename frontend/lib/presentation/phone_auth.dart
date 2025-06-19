import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final TextEditingController _phoneCtlr = TextEditingController();
  final TextEditingController _otpCtlr = TextEditingController();
  String _status = '';
  String _verificationId = '';
  bool _codeSent = false;

  Future<void> _sendCode() async {
    final auth = FirebaseAuth.instance;
    setState(() => _status = 'Sending code...');
    try {
      await auth.verifyPhoneNumber(
        phoneNumber: _phoneCtlr.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only: auto handles code in some cases
          await auth.signInWithCredential(credential);
          setState(() => _status = 'Auto-verified and signed in!');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _status = 'Invalid phone number: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _status = 'Code sent! Enter OTP below.';
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _status = 'Failed to send code: $e');
    }
  }

  Future<void> _verifyCode() async {
    final auth = FirebaseAuth.instance;
    setState(() => _status = 'Verifying code...');
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpCtlr.text.trim(),
      );
      await auth.signInWithCredential(credential);
      setState(() => _status = 'Phone number verified and signed in!');
    } catch (e) {
      setState(() => _status = 'Failed to verify: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Authentication')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _phoneCtlr,
              decoration: const InputDecoration(labelText: 'Phone Number (+91...)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            if (!_codeSent)
              ElevatedButton(
                onPressed: _sendCode,
                child: const Text('Send OTP'),
              ),
            if (_codeSent) ...[
              TextField(
                controller: _otpCtlr,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _verifyCode,
                child: const Text('Verify OTP'),
              ),
            ],
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
