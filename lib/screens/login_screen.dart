import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    
    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailCtrl.text.trim(), 
          password: _passCtrl.text.trim()
        );
      } else {
        await supabase.auth.signUp(
          email: _emailCtrl.text.trim(), 
          password: _passCtrl.text.trim()
        );
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created! Logging in...")));
      }
      
      // Navigate if auth successful
      if (mounted && supabase.auth.currentSession != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScaffold()), 
          (route) => false
        );
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred. Check connection."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replaced Placeholder Icon with styled text or Asset if you have one
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B3E96).withOpacity(0.1),
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.school, size: 60, color: Color(0xFF5B3E96)),
              ),
              const SizedBox(height: 24),
              Text(_isLogin ? "Welcome Back" : "Join MYKerawang", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_isLogin ? "Login to continue" : "Create an account to get started", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailCtrl, 
                decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl, 
                obscureText: true, 
                decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3E96), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? "Login" : "Sign Up", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: RichText(
                  text: TextSpan(
                    text: _isLogin ? "New user? " : "Have an account? ",
                    style: const TextStyle(color: Colors.grey),
                    children: [
                      TextSpan(text: _isLogin ? "Create account" : "Login", style: const TextStyle(color: Color(0xFF5B3E96), fontWeight: FontWeight.bold))
                    ]
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}