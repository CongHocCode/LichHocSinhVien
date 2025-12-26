// lib/screens/man_hinh_lich.dart

//import 'dart:convert'; //De dung jsonEncode jsonDecode TOASK
import 'dart:io'; // Để dùng Platform
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart'; // Để check quyền báo thức
import 'package:shared_preferences/shared_preferences.dart'; //De luu du lieu & check first time

import '../models/mon_hoc.dart'; // Import model
import '../services/danh_sach_service.dart';
import '../services/notification_helper.dart';
import '../services/auto_start_helper.dart';
import '../services/backup_service.dart';
import 'man_hinh_chi_tiet.dart'; // Import man hinh chi tiet
import 'man_hinh_dang_nhap_web.dart';
import '../widgets/the_mon_hoc.dart';    // Import widget Card
import '../widgets/hop_thoai_them.dart'; // Import widget Dialog

//Man hinh chinh (Co the thay doi -> StatefulWidget)
class ManHinhLich extends StatefulWidget {
  const ManHinhLich({super.key});
  @override
  State<ManHinhLich> createState() => _ManHinhLichState();
}

class _ManHinhLichState extends State<ManHinhLich> {
  // Khởi tạo Service để quản lý dữ liệu
  final DanhSachService _service = DanhSachService();
  
  //Ngày đầu tuần đang xem(Mặc định là thứ 2 tuần này)
  late DateTime _ngayDauTuan; 

  @override
  void initState() {
    super.initState();
    NotificationHelper.xinQuyenThongBao(); //Xin quyền thông báo
    
    // 1. Logic tìm ngày Thứ 2 của tuần hiện tại
    final now = DateTime.now();
    // Reset giờ về 00:00:00 để so sánh cho chuẩn (Quan trọng!)
    final DateTime today = DateTime(now.year, now.month, now.day); 
    
    // Công thức: Lấy ngày hiện tại TRỪ ĐI (Thứ trong tuần - 1)
    _ngayDauTuan = today.subtract(Duration(days: now.weekday - 1));

    _khoiTaoDuLieu();
    _checkFirstTime();
  }

  //Kiểm tra có phải lần đầu mở app không, nếu phải thì mở hướng dẫn
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance(); //Lấy một cái kho lưu trữ duy nhất (singleton)
    bool? daXemHuongDan = prefs.getBool('first_time_v1');  //Đọc thử xem có dòng nào là 'first_time_v1' chưa

    //Chưa mở app lần nào, hoặc chưa xem hướng dẫn thì cho xem hướng dẫn
    if (daXemHuongDan == null || daXemHuongDan == false) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) { 
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Chào mừng đến SIVI! 🐧"),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Đây là trợ lý lịch học cá nhân của bạn."),
                  SizedBox(height: 10),
                  Text("✨ Tính năng nổi bật:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("• Đồng bộ lịch từ Web trường (Menu 3 chấm)."),
                  Text("• Nhắc nhở lịch học tự động."),
                  Text("• Quản lý lịch cá nhân."),
                  SizedBox(height: 10),
                  Text("⚠️ Lưu ý quan trọng:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  Text("Nếu bạn dùng OPPO/Xiaomi và gặp lỗi thông báo, hãy vào Menu > Sửa lỗi không báo để cấp quyền chạy nền nhé!"),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  // Lưu lại là đã xem
                  prefs.setBool('first_time_v1', true);
                  Navigator.pop(ctx);
                },
                child: const Text("Đã hiểu, bắt đầu thôi!"),
              )
            ],
          ),
        );
      }
    }
  }

  // Gọi Service đọc dữ liệu từ ổ cứng lên
  Future<void> _khoiTaoDuLieu() async {
    await _service.loadData();
    setState(() {}); // Vẽ lại màn hình khi có dữ liệu
  }

  // --- HÀM TẠO DỮ LIỆU MẪU (Dùng để test nhanh) ---
  void _taoDuLieuMau() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); 

    MonHoc taoMon(String ten, int lechNgay, String gio, String phong) {
      return MonHoc(
        tenMon: ten,
        phongHoc: phong,
        thoiGian: gio,
        ngayHoc: today.add(Duration(days: lechNgay)), 
        giangVien: "GV. Demo",
        ghiChu: "Dữ liệu mẫu tự động tạo",
        nhacTruoc: 15,
      );
    }

    int offsetThu2 = 1 - now.weekday; 

    List<MonHoc> dataMau = [
      taoMon("Lập trình C++", offsetThu2, "07:00", "B101"),      
      taoMon("Đại số tuyến tính", offsetThu2, "09:30", "A202"),  
      taoMon("Cấu trúc dữ liệu", offsetThu2 + 2, "13:00", "C303"), 
      taoMon("Tiếng Anh CN", offsetThu2 + 3, "07:00", "Online"),   
      taoMon("Thực hành C++", offsetThu2 + 7, "07:00", "Lab 1"), 
      taoMon("Kỹ năng mềm", offsetThu2 + 9, "08:00", "Hội trường"), 
    ];

    await _service.lamMoiDanhSach(dataMau);
    setState(() {}); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đã tạo dữ liệu mẫu thành công!")),
    );
  }

  // --- Hàm hiển thị form nhập (Thêm mới) ---
  void _hienThiFormThem() async {
    final result = await showDialog<dynamic>( 
      context: context,
      builder: (context) => const HopThoaiThemMon(),
    );

    if (result != null) {
      if (result is List<MonHoc>) {
        for (var mon in result) {
          await _service.themMon(mon);
        }
      } else if (result is MonHoc) {
        await _service.themMon(result);
      }
      setState(() {});
    }
  }

  // --- Logic đổi tuần ---
  void _doiTuan(int soTuan) {
    setState(() {
      _ngayDauTuan = _ngayDauTuan.add(Duration(days: 7 * soTuan));
    });
  }

  // --- Logic về hôm nay ---
  void _veHomNay() {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _ngayDauTuan = today.subtract(Duration(days: now.weekday - 1));
    });
  }

  // Hàm phụ trợ kiểm tra 2 ngày có trùng nhau không
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tính ngày cuối tuần (Chủ nhật)
    final ngayCuoiTuan = _ngayDauTuan.add(const Duration(days: 6));

    // 2. Logic lọc: Lấy từ Service ra và lọc những môn nằm trong tuần này
    final danhSachHienThi = _service.danhSach.where((mon) {
      return mon.ngayHoc.compareTo(_ngayDauTuan) >= 0 &&
             mon.ngayHoc.compareTo(ngayCuoiTuan.add(const Duration(days: 1))) < 0;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      
      appBar: AppBar(
        toolbarHeight: 70, 
        title: Row(
          children: [
            // --- PHẦN LOGO ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Image.asset(
                'assets/images/penguin.png',
                width: 28, height: 28, fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12), 
            
            // --- PHẦN TÊN APP & NGÀY THÁNG ---
            Expanded( 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("SIVI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  Text(
                    "${DateFormat('dd/MM').format(_ngayDauTuan)} - ${DateFormat('dd/MM').format(_ngayDauTuan.add(const Duration(days: 6)))}",
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,

        // --- Các nút điều hướng & Menu ---
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _doiTuan(-1)),
          IconButton(icon: const Icon(Icons.today), onPressed: _veHomNay),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _doiTuan(1)),
          
          // Menu 3 chấm (Popup)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'mau') {
                _taoDuLieuMau();
              } else if (value == 'xoa_het') {
                await _service.lamMoiDanhSach([]); 
                setState(() {});
              } else if (value == 'fix_loi') {
                AutoStartHelper.fixLoiThongBao(context);
              } else if (value == 'backup') {
                await BackupService.taoBanSaoLuu(context, _service.danhSach);
              } else if (value == 'restore') {
                bool thanhCong = await BackupService.khoiPhucDuLieu(context, _service);
                if (thanhCong) {
                  setState(() {});
                  // Hiện hộp thoại hỏi đồng bộ Web
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Cập nhật dữ liệu?"),
                      content: const Text("Dữ liệu lịch học vừa khôi phục có thể đã cũ.\nBạn có muốn đăng nhập vào Web trường để đồng bộ lịch mới nhất không?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Không cần")),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx); 
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ManHinhDangNhapWeb())).then((_) {
                              _khoiTaoDuLieu();
                            });
                          },
                          child: const Text("Đồng bộ ngay"),
                        ),
                      ],
                    ),
                  );
                }
              } 
              // --- NÚT ĐỒNG BỘ WEB ---
              else if (value == 'web') { 
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ManHinhDangNhapWeb()),
                );
                print("Đã quay về từ Web, đang tải lại dữ liệu...");
                await _khoiTaoDuLieu(); 

                // Kiểm tra quyền Báo thức sau khi đồng bộ
                if (Platform.isAndroid) {
                  if (await Permission.scheduleExactAlarm.isDenied) {
                    if (context.mounted) {
                       showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Cần cấp quyền Báo thức"),
                          content: const Text("Để App nhắc lịch đúng giờ các môn vừa đồng bộ, vui lòng cấp quyền!"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Để sau")),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await Permission.scheduleExactAlarm.request();
                              },
                              child: const Text("Cấp quyền ngay"),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'mau', child: Row(children: [Icon(Icons.data_array, color: Colors.blue), SizedBox(width: 10), Text("Tạo dữ liệu mẫu")])),
              const PopupMenuItem(value: 'xoa_het', child: Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 10), Text("Xóa tất cả")])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'backup', child: Row(children: [Icon(Icons.cloud_upload, color: Colors.blue), SizedBox(width: 10), Text("Sao lưu dữ liệu")])),
              const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.cloud_download, color: Colors.green), SizedBox(width: 10), Text("Khôi phục dữ liệu")])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'fix_loi', child: Row(children: [Icon(Icons.build_circle, color: Colors.orange), SizedBox(width: 10), Text("Sửa lỗi không báo")])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'web', child: Row(children: [Icon(Icons.public, color: Colors.blue), SizedBox(width: 10), Text("Đồng bộ từ Web")])),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _hienThiFormThem,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      body: danhSachHienThi.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text("Tuần này rảnh rỗi!", style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 10, left: 10, right: 10),
              itemCount: danhSachHienThi.length,
              itemBuilder: (context, index) {
                final mon = danhSachHienThi[index];
                String ngayHienThi = DateFormat('EEEE, dd/MM', 'vi').format(mon.ngayHoc).toUpperCase();

                bool hienDauMuc = true;
                if (index > 0) {
                  if (isSameDay(mon.ngayHoc, danhSachHienThi[index - 1].ngayHoc)) {
                    hienDauMuc = false;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hienDauMuc)
                      Container(
                        margin: const EdgeInsets.only(top: 15, bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100, 
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ngayHienThi,
                          style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),

                    TheMonHoc(
                      monHoc: mon,
                      onBamVao: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManHinhChiTiet(
                              monHoc: mon,
                              hamXoa: () async {
                                await _service.xoaMon(mon);
                                setState(() {});
                              },
                              hamSua: (monMoi) async {
                                await _service.suaMon(mon, monMoi);
                                setState(() {});
                              },
                            ),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}