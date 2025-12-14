//lib/services/danh_sach_service.dart


import 'dart:convert'; //De dung jsonEncode jsonDecode 
import 'package:shared_preferences/shared_preferences.dart'; //Để lưu dữ liệu
import '../models/mon_hoc.dart';

class DanhSachService {
  //Biến chứa danh sách dữ liệu (private)
  List<MonHoc> _danhSach = [];

  //Getter
  List<MonHoc> get danhSach => _danhSach;

  //--- 1. Đọc dữ liệu từ ổ cứng ---
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    String? dataJson = prefs.getString('lich_hoc_v2');

    if (dataJson != null) {
      List<dynamic> jsonList = jsonDecode(dataJson);
      _danhSach = jsonList.map((e) => MonHoc.fromJson(e)).toList(); //TOASK
      _sapXep(); //Đọc xong sắp xếp lại
    } 
  }


  //--- 2. Lưu dữ liệu xuống ổ cứng ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    String dataJson = jsonEncode(_danhSach.map((e) => e.toJson()).toList()); //TOASK
    await prefs.setString('lich_hoc_v2', dataJson);
  }


  //--- 3. Thêm môn ---
  Future<void> themMon(MonHoc mon) async {
    _danhSach.add(mon);
    _sapXep();
    await _saveData();
  }

  //--- 4. Xóa môn ---
  Future<void> xoaMon(MonHoc mon) async {
    _danhSach.remove(mon);
    await _saveData();
  }

  //--- 5. Sửa môn ---
  Future<void> suaMon(MonHoc monCu, MonHoc monMoi) async {
    int index = _danhSach.indexOf(monCu);
    if (index != -1) {
      _danhSach[index] = monMoi;
      _sapXep();
      await _saveData();
    }
  }


  //--- 6. Thuật toán sắp xếp ---
  void _sapXep() {
    _danhSach.sort((a, b) {
      int cmp = a.ngayHoc.compareTo(b.ngayHoc);
      if (cmp != 0) return cmp;
      return a.thoiGian.compareTo(b.thoiGian);
    });
  }
}
