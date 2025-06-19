import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _contactCtrl = TextEditingController();
  bool _isSending = false;

  static const _notifyUrl = 'http://localhost:3000/api/notify';

  Future<void> _sendWelcome() async {
    final input = _contactCtrl.text.trim();
    final isPhone = input.startsWith('+');
    final isEmail = input.contains('@');

    if (!isPhone && !isEmail) {
      _showSnack('Enter a valid phone number (+91…) or email address.');
      return;
    }

    setState(() => _isSending = true);

    try {
      if (isPhone) {
        final smsResp = await http.post(
          Uri.parse(_notifyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': input,
            'text': '👋 Welcome to CtoC Broker! Thanks for visiting.',
            'channel': 'whatsapp',
          }),
        );
        if (smsResp.statusCode != 200) {
          throw 'WhatsApp error: ${smsResp.statusCode}';
        }
      }
      

      if (isEmail) {
        final emailResp = await http.post(
          Uri.parse(_notifyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'to': input,
            'text': '👋 Hello! Welcome to CtoC Broker. We’ll be in touch!',
            'channel': 'email',
          }),
        );
        if (emailResp.statusCode != 200) {
          throw 'Email error: ${emailResp.statusCode}';
        }
      }

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _showSnack('Failed to send welcome: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _contactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = _contactCtrl.text.trim();
    final isValid = input.startsWith('+') || input.contains('@');

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6FD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                "Welcome to CtoC Broker",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Enter your phone number (+91…) or email. To connect with us",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _contactCtrl,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Phone number or Email',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isValid && !_isSending ? _sendWelcome : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Get Started"),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
