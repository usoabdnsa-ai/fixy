import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/shared/splash.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

// Photo credits (CC0 / public domain via Openverse, attribution not required):
// see assets/CREDITS.txt.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: C.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const FixyApp()));
}

class FixyApp extends StatelessWidget {
  const FixyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fixy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // On web/desktop, frame the app at phone width so the prototype reads as mobile.
      builder: (context, child) {
        final w = MediaQuery.sizeOf(context).width;
        if (w <= 520) return child!;
        return ColoredBox(
          color: const Color(0xFFE6DDCC),
          child: Center(
            child: Container(
              width: 420,
              height: MediaQuery.sizeOf(context).height,
              decoration: const BoxDecoration(
                border: Border.symmetric(vertical: BorderSide(color: C.ink, width: 2)),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: Size(416, MediaQuery.sizeOf(context).height)),
                child: child!,
              ),
            ),
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

/// Fade + slight rise route used between top-level flows.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 220),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, a, _, child) {
    final c = CurvedAnimation(parent: a, curve: M.out);
    return FadeTransition(
      opacity: c,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(c),
        child: child,
      ),
    );
  },
);
