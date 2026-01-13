// main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// NOTE: You MUST generate this file by running 'flutterfire configure'
import 'firebase_options.dart'; 
// test git
// NOTE: Import your UI and Service files here!
import 'package:cpp/firebase/auth_ui_screen.dart';


// --- MAIN FUNCTION (Separate as requested) ---

void main() async {
  // Required to ensure Firebase is ready before runApp()
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Firebase Auth App',
      home: AuthWrapper(), // Start the application with the navigation logic
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'pages/login_page.dart';
// import 'pages/register_page.dart';
// import 'pages/home_page.dart';
// import 'pages/upload_page.dart';
// // import 'firebase_options.dart'; // if you used the FlutterFire CLI

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     // options: DefaultFirebaseOptions.currentPlatform, // or omit if using google-services files + manual setup
//   );
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'User App',
//       initialRoute: '/login',
//       routes: {
//         '/login': (c)=> const LoginPage(),
//         '/register': (c)=> const RegisterPage(),
//         '/home': (c)=> const HomePage(),
//         '/upload': (c) => const UploadPage(),

//       },
//     );
//   }
// }

// AWS WORKING PUT & GET request:-
// main.dart

// import 'package:flutter/material.dart';
// import 'package:amplify_flutter/amplify_flutter.dart';
// import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
// import 'package:amplify_storage_s3/amplify_storage_s3.dart';
// import 'package:amplify_authenticator/amplify_authenticator.dart';
// import 's3_upload_screen.dart'; // Import your screen
// import 'amplifyconfiguration.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     _configureAmplify();
//   }

//   // 1. Configure Amplify
//   Future<void> _configureAmplify() async {
//     try {
//       // Add Auth and Storage plugins
//       await Amplify.addPlugins([
//         AmplifyAuthCognito(),
//         AmplifyStorageS3(),
//       ]);

//       // Amplify configuration is usually read from amplifyconfiguration.json
//       await Amplify.configure(amplifyconfig); 
//       safePrint('Amplify configured successfully.');

//     } on Exception catch (e) {
//       safePrint('Error configuring Amplify: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Authenticator handles sign-in/sign-up before showing HomeScreen
//     return Authenticator(
//       child: MaterialApp(
//         title: 'S3 Uploader',
//         builder: Authenticator.builder(),
//         home: const S3UploadScreen(),
//       ),
//     );
//   }
// }


// Firebase test:


// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;// Core Auth
// import 'package:firebase_ui_auth/firebase_ui_auth.dart'; // Core UI Widgets (Contains all provider classes)

// // We no longer need this import when using standard EmailAuthProvider
// // import 'package:firebase_auth/firebase_auth.dart' as FBAuth; 

// // Replace this with the actual path to your generated file:
// import 'firebase_options.dart'; 
// import 's3_replacement_screen.dart'; // The screen where file logic lives

// // 1. Declare a global variable to hold the initialized FirebaseApp instance
// late final FirebaseApp firebaseApp;

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // 1. Initialize Firebase and assign the instance to the global variable
//   firebaseApp = await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
  
//   // 2. Configure the available providers for FirebaseUI
//   FirebaseUIAuth.configureProviders([
//     // FIX: Switched to standard EmailAuthProvider()
//     EmailAuthProvider(),
//     // MFA will be handled automatically by the SignInScreen if enabled in Console
//   ]);
  
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Firebase Film Uploader',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const AuthGate(), 
//     );
//   }
// }

// // === AuthGate ===
// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(), 
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return SignInScreen(
//             // Access providers using providersFor and pass the global app instance
//             providers: FirebaseUIAuth.providersFor(firebaseApp), 
//             headerBuilder: (context, constraints, shrinkOffset) {
//               return const Padding(
//                 padding: EdgeInsets.only(top: 100),
//                 child: Center(child: Text("Welcome to Film App")),
//               );
//             },
//             actions: const [
              
//             ],
//             // You can optionally enable registration here
//             // flow: AuthFlow.redirect, 
//           ); 
//         }
        
//         return const S3ReplacementScreen(); 
//       },
//     );
//   }
// }

