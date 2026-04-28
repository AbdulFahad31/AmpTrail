import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amptrail_mini/utils/theme_provider.dart';
import 'package:amptrail_mini/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:amptrail_mini/config/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using google-services.json
  await Firebase.initializeApp();
  
  debugPrint("DEBUG: Firebase initialized with Project Number: ${Firebase.app().options.messagingSenderId}");
  
  // Initialize Mapbox with the token
  MapboxOptions.setAccessToken(MAPBOX_TOKEN);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AmpTrailApp(),
    ),
  );
}

class AmpTrailApp extends StatelessWidget {
  const AmpTrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'AmpTrail',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}