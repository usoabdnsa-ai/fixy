import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/shared/splash.dart';
import 'state/app_state.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';
import 'widgets/kit.dart';

// Photo credits (CC0 / public domain via Openverse, attribution not required):
// see assets/CREDITS.txt.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: C.card,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  if (Uri.base.queryParameters['theme'] == 'light') C.light.value = true;
  // Colors are read from C at build time, so a theme flip just needs every
  // element (including cached route pages) to build again.
  C.light.addListener(() {
    void dirty(Element e) {
      e.markNeedsBuild();
      e.visitChildren(dirty);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(dirty);
  });
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const FixyApp()),
  );
}

class FixyApp extends StatelessWidget {
  const FixyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: C.light,
      builder: (context, light, _) => MaterialApp(
        title: 'Fixy',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // On web/desktop, frame the app at phone width so the prototype reads as mobile.
        builder: (context, child) {
          final w = MediaQuery.sizeOf(context).width;
          if (w <= 520) return child!;
          return ColoredBox(
            color: const Color(0xFFE9E4DA),
            child: Center(
              child: Container(
                width: 420,
                height: MediaQuery.sizeOf(context).height,
                decoration: const BoxDecoration(boxShadow: lift),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(416, MediaQuery.sizeOf(context).height),
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}

/// Top-level flow route: a volt band wipes the new screen in.
Route<T> fadeRoute<T>(Widget page) => wipeRoute<T>(page);
