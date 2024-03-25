import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pli/providers/google_sign_in_provider.dart';
import 'package:pli/views/login.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => GoogleSignInProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final googleSignInProvider = Provider.of<GoogleSignInProvider>(context);
    googleSignInProvider.initializeGoogleSignIn();

    return MaterialApp(
      title: 'Your App',
      home: Login(),
    );
  }
}