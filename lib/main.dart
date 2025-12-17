// lib/main.dart
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'screens/man_hinh_lich.dart'; // Import man hinh chinh
import 'services/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.init();
  await initializeDateFormatting('vi', null); 
  
  runApp(const MyApp());
}

//Widget goc
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ManHinhLich(), // Goi man hinh lich da tach ra file rieng
    );
  }
}
