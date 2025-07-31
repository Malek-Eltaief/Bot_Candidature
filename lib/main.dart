import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/signup_screen.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/add_job_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/job_details_screen.dart';
import 'screens/job_application_chatbot.dart';
import 'theme/theme.dart';
import 'models/application_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApplicationState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Job Candidature',
        theme: lightMode,
        initialRoute: '/welcome',
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/home': (context) => const HomeScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/add_job': (context) => const AddJobScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/job_details': (context) => JobDetailsScreen(
                jobId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
              ),
          '/chat': (context) => ChangeNotifierProvider(
              create: (_) => ApplicationState(), // Create ApplicationState here
              child: JobApplicationChatbot(
                jobData: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?,
              ),
            ),
        },
      ),
    );
  }
}