import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/buttons/custom_button.dart';
import '../../components/form/custom_input.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true; // To toggle password visibility

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await context.read<AuthProvider>().signUp(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await context.read<AuthProvider>().signInWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back arrow button in a circular container
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.grey,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Title: "Sign Up"
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 32),
                // Full Name Label
                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Full Name Input Field
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100], // Light grey background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), // Oval shape
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email Label
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Email Input Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100], // Light grey background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), // Oval shape
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password Label
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Password Input Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100], // Light grey background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24), // Oval shape
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Terms and Conditions Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    children: [
                      const TextSpan(text: 'By signing up, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: const Color(0xFF1A3C34),
                          fontWeight: FontWeight.w500,
                        ),
                        // Add onTap handler if needed
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: const Color(0xFF1A3C34),
                          fontWeight: FontWeight.w500,
                        ),
                        // Add onTap handler if needed
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Sign Up Button (Dark Green)
                CustomButton(
                  onPressed: authProvider.isLoading ? null : _handleSignUp,
                  isLoading: authProvider.isLoading,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  color: const Color(0xFF1A3C34), // Dark green color from the image
                ),
                // Error message if sign-up fails
                if (authProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    authProvider.error!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                // Continue with Google Button
                OutlinedButton.icon(
                  onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                  ),
                  label: const Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24), // Oval shape
                    ),
                    side: BorderSide(color: Colors.grey[300]!), // Grey border
                  ),
                ),
                const SizedBox(height: 16),
                // Continue with Apple Button
                OutlinedButton.icon(
                  onPressed: () {
                    // Add Apple sign-in logic here if needed
                  },
                  icon: const Icon(
                    Icons.apple,
                    color: Colors.black,
                    size: 24,
                  ),
                  label: const Text(
                    'Continue with Apple',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24), // Oval shape
                    ),
                    side: BorderSide(color: Colors.grey[300]!), // Grey border
                  ),
                ),
                const SizedBox(height: 24),
                // "Already have an account? Sign In" link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/auth/signin');
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}