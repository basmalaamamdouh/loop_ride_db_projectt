import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uber_db_project/Authentications/signup_screen.dart';

import '../globall/global.dart';
import '../methods/common_methods.dart';
import '../pages/home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  signinFormValidation() {
    if (_emailController.text.trim().isEmpty) {
      cMethods.displaysnackBar("Email field cannot be empty.", context);
    } else if (!_emailController.text.contains("@") ||
        !_emailController.text.contains(".")) {
      cMethods.displaysnackBar("Please enter a valid email address.", context);
    } else if (_passwordController.text.trim().isEmpty) {
      cMethods.displaysnackBar("Password field cannot be empty.", context);
    } else if (_passwordController.text.trim().length < 8) {
      cMethods.displaysnackBar(
          "Your password must be at least 8 characters.", context);
    } else {
      signInUser();
    }
  }

  // Sign in with Firebase Authentication
  signInUser() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          Center(child: CircularProgressIndicator()),
    );

    final User? firebaseUser = (await fAuth
            .signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    )
            .catchError((msg) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error: $msg");
    }))
        .user;

    if (firebaseUser != null) {
      currentFirebaseUser = firebaseUser;
      Fluttertoast.showToast(msg: "Login Successful.");
      Navigator.push(
          context, MaterialPageRoute(builder: (c) =>  HomePage()));
    } else {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error Occurred during Login");
    }

    // try {
    //   FirebaseAuth auth = FirebaseAuth.instance;
    //   UserCredential userCredential = await auth.signInWithEmailAndPassword(
    //     email: _emailController.text.trim(),
    //     password: _passwordController.text.trim(),
    //   );
    //
    //   Navigator.pop(context); // Close the dialog
    //   cMethods.displaysnackBar("Logged in successfully! Welcome, ${userCredential.user!.email}", context);
    //
    //   // Navigate to the Home Screen after login (replace with your actual screen)
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (c) => HomePage()), // Replace with your actual home screen
    //   );
    // } on FirebaseAuthException catch (e) {
    //   Navigator.pop(context); // Close the dialog
    //   String errorMessage;
    //   if (e.code == 'user-not-found') {
    //     errorMessage = "No user found for that email.";
    //   } else if (e.code == 'wrong-password') {
    //     errorMessage = "Wrong password provided.";
    //   } else {
    //     errorMessage = "Login failed: ${e.message}";
    //   }
    //   cMethods.displaysnackBar(errorMessage, context);
    // } catch (e) {
    //   Navigator.pop(context); // Close the dialog
    //   cMethods.displaysnackBar("An unexpected error occurred: ${e.toString()}", context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Login",
              style: TextStyle(
                fontSize: 30.0,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.yellow),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(
                    color: Colors.yellow), // Optional: Yellow label
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: Colors.grey), // Border color when not focused
                  borderRadius: BorderRadius.circular(30.0), // Circular border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: Colors.amber), // Border color when focused
                  borderRadius: BorderRadius.circular(30.0), // Circular border
                ),
                prefixIcon: const Icon(Icons.email,
                    color: Colors.yellow), // Optional: Yellow icon
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.yellow),// Hide password characters
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "******",

                labelStyle: const TextStyle(
                    color: Colors.yellow), // Optional: Yellow label
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: Colors.grey), // Border color when not focused
                  borderRadius: BorderRadius.circular(30.0), // Circular border
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: Colors.amber), // Border color when focused
                  borderRadius: BorderRadius.circular(30.0), // Circular border
                ),
                prefixIcon: const Icon(Icons.lock,
                    color: Colors.yellow), // Optional: Yellow icon
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed:
                  signinFormValidation, // Call validation before signing in
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.amber, // Match with text field's yellow theme
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // Circular edges
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 15), // Bigger size
              ),
              child: const Text(
                "Login",
                style: TextStyle(
                  fontSize: 18, // Increase font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Black text for contrast
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white, // Match the yellow theme
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => SignupScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amber, // Match the yellow theme
                    textStyle: const TextStyle(
                      fontSize: 16, // Increase font size
                      fontWeight: FontWeight.bold, // Bold text
                    ),
                  ),
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
