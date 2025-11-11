import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reorderable_list/core/services/hive_service.dart';
import 'package:reorderable_list/core/services/service_locator.dart';
import 'package:reorderable_list/features/home/bloc/task_queue_bloc.dart';
import 'package:reorderable_list/features/splash/splash_screen.dart';
import 'package:reorderable_list/routes/routes.dart';
import 'package:reorderable_list/theme/darkmode_bloc.dart';
import 'package:reorderable_list/theme/darkmode_state.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveSetup.init();
  await setUpLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DarkModeBloc()),
        BlocProvider(create: (context) => TaskQueueBloc()),
      ],
      child: BlocBuilder<DarkModeBloc, DarkModeState>(
        builder: (context, state) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            enableScaleText: () {
              return true;
            },
            enableScaleWH: () {
              return true;
            },
            ensureScreenSize: true,
            splitScreenMode: true,
            builder: (context, child) => MaterialApp(
              supportedLocales: const [Locale('en', 'US')],

              title: 'Reorderable Task Manager',

              debugShowCheckedModeBanner: false,
              theme: ThemeData(useMaterial3: true, fontFamily: 'Geist'),
              home: child,
              onGenerateRoute: Routes.onGenerateRoute,
              navigatorObservers: [routeObserver],
            ),
            child: const SplashScreen(),
          );
        },
      ),
    );
  }
}
