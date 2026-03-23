import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _profileImageUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  Future<void> _register() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();
    final String username = _usernameController.text.trim().toLowerCase();
    final String fullName = _fullNameController.text.trim();
    final String profileUrl = _profileImageUrlController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final finalProfileUrl = profileUrl.isNotEmpty 
          ? profileUrl 
          : 'https://i.pravatar.cc/150?u=${userCredential.user!.uid}';

      // IMPORTANT: Update Firebase Auth Display Name & Photo
      await userCredential.user!.updateDisplayName(fullName);
      await userCredential.user!.updatePhotoURL(finalProfileUrl);

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'username': username,
        'fullName': fullName,
        'bio': 'New to SnapTalk Buddy ✨',
        'profileImageUrl': finalProfileUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'followers': [],
        'following': [],
      });

      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please log in.')));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Registration failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              children: [
                const Text('SnapTalk Buddy', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                _buildField(_usernameController, 'Username'),
                const SizedBox(height: 12),
                _buildField(_fullNameController, 'Full Name'),
                const SizedBox(height: 12),
                _buildField(_profileImageUrlController, 'Profile Image Link (Optional)'),
                const SizedBox(height: 12),
                _buildField(_emailController, 'Email'),
                const SizedBox(height: 12),
                _buildField(_passwordController, 'Password', obscure: _obscurePassword, toggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                const SizedBox(height: 12),
                _buildField(_confirmPasswordController, 'Confirm Password', obscure: _obscureConfirmPassword, toggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {bool obscure = false, VoidCallback? toggle}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide(color: Colors.grey[300]!)),
        suffixIcon: toggle != null ? IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility), onPressed: toggle) : null,
      ),
    );
  }
}
