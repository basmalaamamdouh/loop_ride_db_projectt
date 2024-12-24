import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../globall/global.dart';
import '../methods/common_methods.dart';
import '../pages/home_page.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  checkIfNetworkIsAvailable()
  {
    cMethods.checkConnectivity(context);

  }
  signUpFormValidation()
  {
    if (_username.text.trim().length < 3)
    {
      cMethods.displaysnackBar("Your name must be atleast 4 or more characters. ", context);
    }
    else if (_passwordController.text.trim().length < 8)
    {
      cMethods.displaysnackBar("Your password must be atleast 8 or more characters. ", context);
    }
    else if (_phoneController.text.trim().length < 11)
    {
      cMethods.displaysnackBar("Your phone must be atleast 8 or more numbers. ", context);
    }
    else if (!_emailController.text.contains("@"))
    {
      cMethods.displaysnackBar("Please enter valid email. ", context);
    }
    else
    {
      registerNewUser();
    }
  }


  registerNewUser()async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context )=> Center(child: CircularProgressIndicator(),),
    );


    final User? firebaseUser = (
        await fAuth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ).catchError((msg){
          Navigator.pop(context);
          Fluttertoast.showToast(msg: "Error: $msg");
        })
    ).user;

    if(firebaseUser != null)
    {
      Map userMap =
      {
        "id" : firebaseUser.uid,
        "name" :_username.text.trim(),
        "email" :_emailController.text.trim(),
        "phone" :_phoneController.text.trim(),
      };

      DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("users");
      driversRef.child(firebaseUser.uid).set(userMap);

      currentFirebaseUser = firebaseUser;
      Fluttertoast.showToast(msg: "Account has been Created.");
      Navigator.push(context, MaterialPageRoute(builder: (c)=> const LoginScreen()));


    }
    else
    {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Account has not been Created.");
    }

    // try {
    //   FirebaseAuth auth = FirebaseAuth.instance;
    //   UserCredential userCredential = await auth.createUserWithEmailAndPassword(
    //     email: _emailController.text.trim(),
    //     password: _passwordController.text.trim(),
    //   );
    //
    //   Navigator.pop(context); // Close the dialog
    //   cMethods.displaysnackBar(
    //       "Registration successful! Welcome, ${userCredential.user!.email}",
    //       context);
    //
    //   // Optionally navigate to another screen
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (c) => HomePage()),
    //   );
    // } on FirebaseAuthException catch (e) {
    //   Navigator.pop(context); // Close the dialog
    //   if (e.code == 'email-already-in-use') {
    //     cMethods.displaysnackBar("Email is already in use.", context);
    //   } else if (e.code == 'weak-password') {
    //     cMethods.displaysnackBar("Password is too weak.", context);
    //   } else {
    //     cMethods.displaysnackBar("Error: ${e.message}", context);
    //   }
    // } catch (e) {
    //   Navigator.pop(context); // Close the dialog
    //   cMethods.displaysnackBar("An error occurred. Please try again.", context);
    // }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
        ),
        body: SingleChildScrollView(
          child:
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text("Sign up",
                  style: TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 20.0,),
    TextFormField(
    controller: _username,
    keyboardType: TextInputType.name,
    style: const TextStyle(color: Colors.yellow),
    decoration: InputDecoration(
    labelText: "Name",
    labelStyle: const TextStyle(color: Colors.yellow),
    enabledBorder: OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.grey),
    borderRadius: BorderRadius.circular(30.0),
    ),focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.amber),
      borderRadius: BorderRadius.circular(30.0),
    ),
      prefixIcon: const Icon(Icons.person, color: Colors.yellow),
    ),
    ),
//phone
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.yellow),
                  decoration: InputDecoration(
                    labelText: "Phone",
                    labelStyle: const TextStyle(color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.yellow),
                  ),
                ),

//email
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.yellow),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.yellow),
                  ),
                ),

                //password
                const SizedBox(height: 20.0,),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.yellow),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.yellow),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber),
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.yellow),
                  ),
                ),

                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () {
                    checkIfNetworkIsAvailable();
                    signUpFormValidation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) =>  LoginScreen()));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.amber,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Log In"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}