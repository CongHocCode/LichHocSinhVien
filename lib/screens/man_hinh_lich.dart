// lib/screens/man_hinh_lich.dart

import 'dart:convert'; //De dung jsonEncode jsonDecode TOASK
import 'package:shared_preferences/shared_preferences.dart'; //De luu du lieu TOASK
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import '../models/mon_hoc.dart'; // Import model
import 'man_hinh_chi_tiet.dart'; // Import man hinh chi tiet

//Man hinh chinh (Co the thay doi -> StatefulWidget)
class ManHinhLich extends StatefulWidget {
  const ManHinhLich({super.key});
  @override
  State<ManHinhLich> createState() => _ManHinhLichState();
}

class _ManHinhLichState extends State<ManHinhLich> {
  //Du lieu mau
  final List<MonHoc> _danhSach = [];

  @override
  void initState() {
    super.initState();
    _docDuLieu();
  }

  //Ham luu du lieu TOASK
  Future<void> _luuDuLieu() async {
    final prefs = await SharedPreferences.getInstance();

    //List<MonHoc> -> List<Map> -> JSON
    //map((e) => e.toJson()) duyet tung phan tu va bien thanh map TOASK
    String dataJson = jsonEncode(_danhSach.map((e) => e.toJson()).toList());

    //Luu chuoi vao o cung voi key la 'lich_hoc_key'
    await prefs.setString('lich_hoc_key', dataJson); //TOASK
    print("Đã lưu dữ liệu: $dataJson");
  }

  //Ham doc du lieu
  Future<void> _docDuLieu() async {
    final prefs = await SharedPreferences.getInstance(); //TOASK

    //Doc chuoi JSON tu o cung
    String? dataJson = prefs.getString('lich_hoc_key');

    if (dataJson != null) {
      //Decode JSON thanh List<dynamic> TOASK
      List<dynamic> jsonList = jsonDecode(dataJson);

      //Bien doi tung phan tu JSON tro lai thanh Object MonHoc
      setState(() {
        _danhSach.clear(); //Xoa du lieu mau cu di
        _danhSach.addAll(
          jsonList.map((e) => MonHoc.fromJson(e)).toList(),
        ); //TOASK
      });
    }
  }

  //Remote dieu khien 3 o nhap (con hoi lu cho nay)
  final _tenController = TextEditingController();
  final _phongController = TextEditingController();
  final _gioController = TextEditingController();

  // --- Ham hien thi form nhap ---
  void _hienThiFormThem() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Thêm môn học mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min, //Lam nho o thoai

            children: [
              //O nhap ten mon
              TextField(
                controller: _tenController,
                decoration: const InputDecoration(
                  labelText: "Tên môn",
                  hintText: "VD: Toán",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),

              //O nhap phong
              TextField(
                controller: _phongController,
                decoration: const InputDecoration(
                  labelText: "Phòng",
                  hintText: "VD: B101",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),

              //O nhap gio
              TextField(
                controller: _gioController,
                readOnly: true, //Khong cho hien ban phim
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),

                //Su kien khi cham vao TOASK
                onTap: () async {
                  int gioChon = TimeOfDay.now().hour;
                  int phutChon = TimeOfDay.now().minute;

                  if (_gioController.text.isNotEmpty) {
                    //Co gang doc gio cu ?
                    try {
                      var parts = _gioController.text.split(':');
                      gioChon = int.parse(parts[0]); //TOASK
                      phutChon = int.parse(parts[1]);
                    } catch (e) {
                      //Neu loi thi thoi, dung gio hien tai
                    }
                  }

                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      //TOASK
                      //StatefulBuider: De so nhay khi cuon
                      return StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return AlertDialog(
                            title: const Text(
                              "Chọn giờ học",
                              textAlign: TextAlign.center,
                            ),
                            content: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                //Cot gio
                                NumberPicker(
                                  value: gioChon,
                                  minValue: 0,
                                  maxValue: 23,
                                  infiniteLoop: true,
                                  itemWidth: 80,
                                  textStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                  selectedTextStyle: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.blueAccent),
                                      bottom: BorderSide(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setStateDialog(() => gioChon = value);
                                  },
                                ),

                                const Text(
                                  ":",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                //Cot phut
                                NumberPicker(
                                  value: phutChon,
                                  minValue: 0,
                                  maxValue: 59,
                                  infiniteLoop: true,
                                  itemWidth: 80,
                                  //Hien thi 0 thanh 00 custom text mapper
                                  textMapper: (numberText) =>
                                      numberText.padLeft(2, '0'),
                                  textStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                  selectedTextStyle: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.blueAccent),
                                      bottom: BorderSide(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setStateDialog(() => phutChon = value);
                                  },
                                ),
                              ],
                            ),

                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Hủy"),
                              ),

                              ElevatedButton(
                                onPressed: () {
                                  String gio = gioChon.toString();
                                  String phut = phutChon.toString().padLeft(
                                    2,
                                    '0',
                                  );
                                  _gioController.text = "$gio:$phut";
                                  Navigator.pop(context);
                                },
                                child: const Text("Xong"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                //Lay du lieu tu controller
                //Kiem tra input
                if (_tenController.text.trim().isEmpty) {
                  //trim de xoa dau cach thua
                  //Hien thong bao tam thoi(Snackbar)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Tên môn học không được để trống!"),
                      backgroundColor: Colors.red,
                      duration: Duration(milliseconds: 500),
                    ),
                  );
                  return;
                }

                //Cap nhat giao dien
                setState(() {
                  _danhSach.add(
                    MonHoc(
                      tenMon: _tenController.text,
                      phongHoc: _phongController.text,
                      thoiGian: _gioController.text,
                    ),
                  );
                });

                _luuDuLieu();

                //Don dep du lieu trong o cho lan nhap sau
                _tenController.clear();
                _phongController.clear();
                _gioController.clear();

                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Thanh tieu de
      appBar: AppBar(
        title: const Text("Thời Khóa Biểu"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),

      //Nut them
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _hienThiFormThem,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      //Danh sach cuon
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _danhSach.length,
        itemBuilder: (context, index) {
          //Lay mon thu index trong danh sach ra
          final mon = _danhSach[index];

          //Ve giao dien cho tung mon
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 5, //Chinh bong do elevation: su nang len
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  mon.tenMon.isNotEmpty ? mon.tenMon[0].toUpperCase() : "?",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ), //Lay chu cai dau cua ten mon
              ),
              title: Text(
                mon.tenMon,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("${mon.thoiGian} | Phòng: ${mon.phongHoc}"),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ), //Icon mui ten
              //Chuyen sang man hinh chi tiet
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManHinhChiTiet(
                      monHoc: mon,
                      hamXoa: () {
                        setState(() {
                          _danhSach.removeAt(index);
                        });
                        _luuDuLieu();
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
