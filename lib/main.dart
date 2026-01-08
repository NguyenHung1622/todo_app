import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'views/todo_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo dịch vụ thông báo
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF191928),
        colorSchemeSeed: const Color(0xFFFF6B81),
      ),
      home: const TodoHomePage(),
    );
  }
}
