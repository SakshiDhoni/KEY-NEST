import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/service/api_service.dart';
import 'dart:convert';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});
  @override
  _EmailAuthPageState createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtlr = TextEditingController();
  final _passwordCtlr = TextEditingController();
  String _status = '';
  bool _isLogin = true;

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtlr.text.trim();
    final password = _passwordCtlr.text.trim();

    if (_isLogin) {
      // 🔐 LOGIN via Firebase Auth
      setState(() => _status = 'Logging in...');
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        setState(() => _status = '✅ Logged in!');
        // Navigate to home if needed
      } on FirebaseAuthException catch (e) {
        setState(() => _status = '❌ Login failed: ${e.message}');
      }
      return;
    }

    // 📝 REGISTER via your Node.js backend
    setState(() => _status = 'Registering...');
    try {
      final response = await ApiService.registerWithEmail(email: email, password: password);
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Try Firebase login after backend registration
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        setState(() => _status = '✅ Registered and logged in!');
      } else {
        setState(() => _status = '❌ Registration failed: ${body['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      setState(() => _status = '❗ Error: $e');
    }
  }

  @override
  void dispose() {
    _emailCtlr.dispose();
    _passwordCtlr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(_isLogin ? 'Switch to Register' : 'Switch to Login'),
              value: _isLogin,
              onChanged: (val) {
                setState(() {
                  _isLogin = val;
                  _status = '';
                });
              },
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailCtlr,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordCtlr,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitEmailAuth,
                    child: Text(_isLogin ? 'Login' : 'Register'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
