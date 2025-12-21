import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Cần thêm cái này để lấy ID gói tự động

class AutoStartHelper {
  
  static Future<void> fixLoiThongBao(BuildContext context) async {
    if (!Platform.isAndroid) return;
    await _xinQuyenPin();
    if (context.mounted) {
      await _checkAutoStart(context);
    }
  }

  static Future<void> _xinQuyenPin() async {
    var status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  static Future<void> _checkAutoStart(BuildContext context) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final String manufacturer = androidInfo.manufacturer.toLowerCase();
    
    // Lấy ID của App mình (com.example.lich_hoc_sv) tự động
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String packageName = packageInfo.packageName;

    // Danh sách các địa chỉ "bí mật" của OPPO (Xếp theo thứ tự ưu tiên)
    final List<Map<String, String>> oppoIntents = [
      // 1. Màn hình quản lý khởi động (ColorOS cũ)
      {
        'package': 'com.coloros.safecenter',
        'component': 'com.coloros.safecenter.permission.startup.StartupAppListActivity'
      },
      {
        'package': 'com.oppo.safe',
        'component': 'com.oppo.safe.permission.startup.StartupAppListActivity'
      },
      // 2. Màn hình quản lý pin (ColorOS mới)
      {
        'package': 'com.coloros.safecenter',
        'component': 'com.coloros.safecenter.startupapp.StartupAppListActivity'
      },
    ];

    if (manufacturer.contains('oppo') || manufacturer.contains('realme') || manufacturer.contains('xiaomi')) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Cấp quyền chạy ngầm"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Để App tự nhắc lịch sau khi khởi động lại, bạn cần bật:", style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              // Hướng dẫn cụ thể dựa trên ảnh bạn gửi
              _buildStep(1, "Bấm nút bên dưới để mở Cài đặt."),
              _buildStep(2, "Chọn mục 'Mức sử dụng pin' (hoặc Pin)."),
              _buildStep(3, "Bật 'Cho phép hoạt động dưới nền'."),
              const SizedBox(height: 10),
              const Text("Nếu thấy mục 'Tự khởi chạy', hãy bật nó lên luôn nhé!", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Để sau")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                
                bool moDuoc = false;
                
                // Chiến thuật 1: Thử mở các trình quản lý chuyên sâu trước
                if (manufacturer.contains('oppo')) {
                  for (var intentMap in oppoIntents) {
                    try {
                      final intent = AndroidIntent(
                        action: 'android.intent.action.MAIN',
                        package: intentMap['package'],
                        componentName: intentMap['component'],
                        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                      );
                      await intent.launch();
                      moDuoc = true;
                      break; 
                    } catch (e) {
                      continue; 
                    }
                  }
                }

                // Chiến thuật 2 (Chắc chắn được): Mở trang Thông tin ứng dụng
                // Đây chính là trang bạn đã chụp ảnh
                if (!moDuoc) {
                  await AndroidIntent(
                    action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
                    data: 'package:$packageName', // Mở đúng cài đặt của App SIVI
                    flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                  ).launch();
                }
              },
              child: const Text("Đi tới Cài đặt"),
            ),
          ],
        ),
      );
    }
  }

  static Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$number. ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}