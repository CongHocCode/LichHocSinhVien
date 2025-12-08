// lib/screens/man_hinh_chi_tiet.dart

import 'package:flutter/material.dart';
import '../models/mon_hoc.dart'; // Import model MonHoc

class ManHinhChiTiet extends StatefulWidget {
  final MonHoc monHoc;
  final VoidCallback hamXoa; //TOASK

  const ManHinhChiTiet({super.key, required this.monHoc, required this.hamXoa});

  @override
  State<ManHinhChiTiet> createState() => _ManHinhChiTietState(); //TOASK
}

class _ManHinhChiTietState extends State<ManHinhChiTiet> {
  //TOASK
  //Controller quan ly o nhap ghi chu
  late TextEditingController _ghiChuController; //TOASK

  @override
  void initState() {
    super.initState();
    //Khoi tao voi noi dung ghi chu hien co
    _ghiChuController = TextEditingController(
      text: widget.monHoc.ghiChu,
    ); //TOASK
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.monHoc.tenMon),
        actions: [
          //TOASK
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              //TOASK syntax
              //Hien bang xac nhan xoa
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Xác nhận"),
                  content: const Text("Bạn có chắc muốn xóa môn này không?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Hủy"),
                    ), //TOASK dau ()
                    TextButton(
                      onPressed: () {
                        widget.hamXoa(); //Goi ham xoa
                        Navigator.pop(ctx); //Dong bang hoi
                        Navigator.pop(context); //Quay ve man hinh chinh TOASK
                      },
                      child: const Text(
                        "Xóa",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ), //TOASK
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, //TOASK
          children: [
            //Thong tin gio va phong
            Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.blue),
                title: Text("Giờ: ${widget.monHoc.thoiGian}"),
                subtitle: Text("Phòng: ${widget.monHoc.phongHoc}"),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Ghi chú:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            //O nhap ghi chu
            TextField(
              controller: _ghiChuController,
              maxLines: 5, //toi da 5 dong duoc hien thi
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "VD: Nhớ mang laptop,...",
              ),
              onChanged: (text) {
                //TOASK
                widget.monHoc.ghiChu = text;
              },
            ),
          ],
        ),
      ),
    );
  }
}
