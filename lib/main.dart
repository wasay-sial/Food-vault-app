import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/user_service.dart';
import 'core/screens/auth/login_screen.dart';
import 'core/screens/home/home_screen.dart';
import 'core/screens/auth/signup_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/models/user_profile.dart';
import 'package:rxdart/rxdart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable high refresh rate
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Enable high refresh rate for the app
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        StreamProvider<UserProfile?>(
          create: (context) =>
              Provider.of<AuthService>(context, listen: false)
                  .authStateChanges
                  .switchMap((user) {
            if (user != null) {
              // User is logged in, stream their profile
              return Provider.of<UserService>(context, listen: false)
                  .getUserProfile(user.uid);
            } else {
              // User is logged out, return a stream with null
              return Stream.value(null);
            }
          }),
          initialData: null,
          catchError: (context, error) {
            print('Error streaming user profile: $error');
            return null;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Food Vault',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.light(
            primary: AppTheme.primaryColor,
            secondary: AppTheme.secondaryColor,
            surface: AppTheme.surfaceColor,
            background: AppTheme.backgroundColor,
            error: AppTheme.errorColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppTheme.textColor,
            onBackground: AppTheme.textColor,
            onError: Colors.white,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppTheme.backgroundColor,
          textTheme: TextTheme(
            displayLarge: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w900),
            displayMedium: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w800),
            displaySmall: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700),
            headlineLarge: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w700),
            headlineMedium: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w600),
            headlineSmall: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w500),
            titleLarge: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w600),
            titleMedium: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w500),
            titleSmall: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w400),
            bodyLarge: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w400),
            bodyMedium: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w400),
            bodySmall: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w400),
            labelLarge: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w600),
            labelMedium: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w500),
            labelSmall: TextStyle(color: AppTheme.textColor, fontFamily: 'PlayfairDisplay', fontWeight: FontWeight.w400),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: AppTheme.primaryColor.withOpacity(0.2),
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                );
              }
              return TextStyle(
                color: AppTheme.textColor.withOpacity(0.7),
                fontSize: 12,
              );
            }),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<User?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            print('Auth state changed. Has data: ${snapshot.hasData}');
            print('Connection state: ${snapshot.connectionState}');
            if (snapshot.hasError) {
              print('Auth stream error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData) {
              print('User is logged in. Showing HomeScreen');
              return const HomeScreen();
            }

            print('No user logged in. Showing LoginScreen');
            return const LoginScreen();
          },
        );
      },
    );
  }
}
