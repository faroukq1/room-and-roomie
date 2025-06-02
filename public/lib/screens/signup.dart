import 'package:flutter/material.dart';
class SignUpFlow extends StatefulWidget {
  const SignUpFlow({Key? key}) : super(key: key);

  @override
  State<SignUpFlow> createState() => _SignUpFlowState();
}

class _SignUpFlowState extends State<SignUpFlow> {
  bool isFirstScreen = true;
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void navigateToNextScreen() {
    setState(() {
      isFirstScreen = false;
    });
  }

  void navigateToPreviousScreen() {
    setState(() {
      isFirstScreen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: isFirstScreen ? () {} : navigateToPreviousScreen,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),

                const SizedBox(height: 40),

                // Sign up text
                const Center(
                  child: Text(
                    'Sign-Up',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Content based on current screen
                if (isFirstScreen) _buildUsernameScreen() else _buildEmailPasswordScreen(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What is your Username?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 20),

        // Username TextField
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            hintText: 'Your Username',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),

        const SizedBox(height: 50),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: navigateToNextScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailPasswordScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email TextField
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email',
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            suffixIcon: const Icon(Icons.email_outlined),
          ),
        ),

        const SizedBox(height: 20),

        // Password TextField
        TextField(
          controller: passwordController,
          obscureText: !passwordVisible,
          decoration: InputDecoration(
            hintText: 'Password',
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  passwordVisible = !passwordVisible;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Confirm Password TextField
        TextField(
          controller: confirmPasswordController,
          obscureText: !confirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Confirm Password',
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  confirmPasswordVisible = !confirmPasswordVisible;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Sign Up Button
        Center(
          child: SizedBox(
            width: 120,
            child: ElevatedButton(
              onPressed: () {
                // Handle sign up logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign up successful!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}