import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(String error) {
    if (error.contains('invalid-credential') || error.contains('INVALID_LOGIN_CREDENTIALS')) {
      return 'Invalid email or password';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    } else if (error.contains('email-not-verified')) {
      return 'Please verify your email before signing in';
    }
    return 'An error occurred. Please try again';
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          // Clear any previous errors
          context.read<AuthProvider>().clearError();
        });
        
        final success = await context.read<AuthProvider>().signIn(
          _emailController.text,
          _passwordController.text,
        );
        
        if (success && mounted) {
          // Navigate to wrapper instead of home
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/',
            (route) => false,
          );
        } else if (mounted) {
          // Show error from provider if there is one
          final error = context.read<AuthProvider>().error;
          if (error != null && error.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getErrorMessage(error)),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() {
        // Clear any previous errors
        context.read<AuthProvider>().clearError();
      });
      
      final success = await context.read<AuthProvider>().signInWithGoogle();
      
      if (success && mounted) {
        // Navigate to wrapper instead of home
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/',
          (route) => false,
        );
      } else if (mounted) {
        // Show error from provider if there is one
        final error = context.read<AuthProvider>().error;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign in with Google: ${_getErrorMessage(error)}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign in with Google: ${_getErrorMessage(e.toString())}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black54,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Sign in to ReliefLink',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back! Please enter your details.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
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
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            activeColor: const Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember Me',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/auth/forgot-password'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4332),
                      ),
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/auth/signup'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1B4332),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
