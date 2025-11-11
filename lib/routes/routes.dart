import 'package:flutter/material.dart';
import 'package:reorderable_list/features/home/presentation/screens/Home_screen.dart';
import 'package:reorderable_list/features/splash/splash_screen.dart';

class Routes {
  static const String splashScreen = 'SplashScreen';
  static const String homeScreen = 'HomeScreen';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    WidgetBuilder builder;

    switch (settings.name) {
      case splashScreen:
        builder = (_) => const SplashScreen();
        break;
      case homeScreen:
        builder = (_) => const HomeScreen();
        break;

      default:
        throw Exception('Invalid route: ${settings.name}');
    }

    // Use a custom transition for all routes
    return SlideFromRightPageRoute(builder: builder, settings: settings);
  }
}

/// Custom transition for routes
class SlideFromRightPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;
  @override
  final RouteSettings settings;

  SlideFromRightPageRoute({required this.builder, required this.settings})
    : super(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Start from right
          const end = Offset.zero; // End at current position
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      );
}
