import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/shared/splash.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: C.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final state = await AppState.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const FixyApp()));
}

class FixyApp extends StatelessWidget {
  const FixyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Fixy',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('fr', 'DZ'),
    // In a desktop browser, frame the app at phone width (the product is Android-only).
    builder: (context, child) {
      final mq = MediaQuery.of(context);
      if (mq.size.width <= 520) return child!;
      return ColoredBox(
        color: const Color(0xFFDDE3E9),
        child: Center(
          child: Container(
            width: 412,
            decoration: const BoxDecoration(boxShadow: lift),
            child: MediaQuery(data: mq.copyWith(size: Size(412, mq.size.height)), child: child!),
          ),
        ),
      );
    },
    home: const SplashScreen(),
  );
}
