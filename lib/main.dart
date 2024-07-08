import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:onboarding_app/routes/app_routes.dart';
import 'animations/storage_service.dart';
import 'dependency_injection.dart';
import 'myApp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    statusBarColor: Colors.transparent.withOpacity(0.0), // status bar color
  ));
  await Get.putAsync(() async => StorageService());
  await GetStorage.init();
  DependencyInjection.init();
  Get.put(GetStorage());
  var initialRoute = await AppPages.initialRoute;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {


    runApp(MyApp(initialRoute));

  });
}



// class MyApp extends StatelessWidget {
//
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.white,
//       statusBarIconBrightness:
//       Brightness.dark, // Change the status bar color here
//       systemNavigationBarColor:
//       Colors.white, // Change the navigation bar color here
//     ));
//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
//         useMaterial3: true,
//       ),
//       locale: Get.locale,
//       fallbackLocale: Locale('en', 'UK'),
//
//
//     );
//   }
//
//
//
// }






