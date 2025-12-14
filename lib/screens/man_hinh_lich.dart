// lib/screens/man_hinh_lich.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; //Ngày giờ quốc tế, format các kiểu
import 'package:lich_hoc_sv/services/danh_sach_service.dart';
import '../models/mon_hoc.dart'; // Import model
import 'man_hinh_chi_tiet.dart'; // Import man hinh chi tiet
import '../widgets/the_mon_hoc.dart'; // Import widget Card
import '../widgets/hop_thoai_them.dart'; // Import widget Dialog

//Man hinh chinh (Co the thay doi -> StatefulWidget)
class ManHinhLich extends StatefulWidget {
  const ManHinhLich({super.key});
  @override
  State<ManHinhLich> createState() => _ManHinhLichState();
}

class _ManHinhLichState extends State<ManHinhLich> {
  //Khởi tạo Service (Quản lý data)
  final DanhSachService _service = DanhSachService();

  late DateTime _ngayDauTuan; //Biến lưu ngày đầu tuần (Thứ 2) đang xem


  @override
  void initState() {
    super.initState();

    // 1. Tính ngày thứ 2 của tuần hiện tại
    final now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day); // Reset giờ về 00:00:00 để so sánh cho chuẩn
    _ngayDauTuan = today.subtract(Duration(days: now.weekday - 1)); // Ví dụ công thức: Thứ 5 (5) - 1 = 4 lùi 4 ngày là về thứ 2


    _khoiTaoDuLieu();
  }

 
 //Gọi service đọc dữ liệu, xong thì vẽ lại màn hình
 Future<void> _khoiTaoDuLieu() async {
  await _service.loadData();
  setState(() {});
 }
 

  // --- Hàm hiển thị form nhập ---
  void _hienThiFormThem() async {
    final ketQua = await showDialog<MonHoc>(
      context: context,
      builder: (context) => const HopThoaiThemMon(),
    );

    if (ketQua != null) {
      await _service.themMon(ketQua);
      setState(() {});
    }
  }


  //--- Logic đổi tuần---
  //soTuan: -1(lùi), +1(tiến)
  void _doiTuan(int soTuan) {
    setState(() {
      _ngayDauTuan = _ngayDauTuan.add(Duration(days: 7 * soTuan));
    });
  }


  // Hàm về tuần hiện tại
  void _veHomNay() {
    setState(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _ngayDauTuan = today.subtract(Duration(days: now.weekday - 1));
    });
  }


  // Hàm phụ trợ kiểm tra 2 ngày có trùng nhau không (để hiện tiêu đề)
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }


  @override
  Widget build(BuildContext context) {
    //1. Tính ngày cuối tuần (Chủ Nhật)
    final ngayCuoiTuan = _ngayDauTuan.add(const Duration(days: 6));

    //2. Logic lọc: Chỉ lấy môn nằm trong khung tuần này 
    //Lấy danh sách từ Services ra để hiển thị
    final danhSachHienThi = _service.danhSach.where((mon) {
      return mon.ngayHoc.compareTo(_ngayDauTuan) >= 0 &&
            mon.ngayHoc.compareTo(ngayCuoiTuan.add(const Duration(days: 1))) < 0;
    }).toList();

    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Thời Khóa Biểu", style: TextStyle(fontSize: 18)),
            Text(
              "Tuần: ${DateFormat('dd/MM').format(_ngayDauTuan)} - ${DateFormat('dd/MM').format(ngayCuoiTuan)}",
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,


        //--- Các nút điều hướng ---
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _doiTuan(-1),
          ),

          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _veHomNay,
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: ()  => _doiTuan(1),
          ),
      ]
      ),


      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _hienThiFormThem,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: danhSachHienThi.isEmpty
          ? const Center(child: Text("Tuần này rảnh rỗi!", style: TextStyle(color: Colors.grey, fontSize: 18)))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: danhSachHienThi.length,
              itemBuilder: (context, index) {
                final mon = danhSachHienThi[index]; //Biến mon tượng trưng cho phần từ trong danh sách

                //Hiển thị thêm ngày tháng để phân biệt
                String ngayHienThi = DateFormat(
                  'EEEE, dd/MM/yyyy',
                ).format(mon.ngayHoc); //TOASK

                bool hienDauMuc = true;
                if (index > 0) {
                  if (isSameDay(mon.ngayHoc, danhSachHienThi[index - 1].ngayHoc)) {
                    hienDauMuc = false;
                  }
                }


                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Chỉ hiện tiêu đề ngày nếu đây là môn đầu tiên, hoặc ngày của môn này KHÁC ngày của môn trước đó.
                    if (hienDauMuc)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(5, 15, 5, 5),
                        child: Text(
                          ngayHienThi,
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
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

                              hamXoa: () async{
                                await _service.xoaMon(mon);
                                setState(() {});
                              },


                              hamSua: (monMoi) async{
                                await _service.suaMon(mon, monMoi);
                                setState(() {});
                              },
                            ),
                          ),
                        );
                        //Quay lại thì reload giao diện
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
