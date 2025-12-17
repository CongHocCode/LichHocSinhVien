//lib/services/danh_sach_service.dart

//De dung jsonEncode jsonDecode 
//Để lưu dữ liệu
import '../models/mon_hoc.dart';
import 'database_helper.dart';
import 'notification_helper.dart';

class DanhSachService {
  //Biến chứa danh sách dữ liệu (private)
  List<MonHoc> _danhSach = [];

  //Getter
  List<MonHoc> get danhSach => _danhSach;

  // Hàm gộp ngày và giờ thành DateTime chuẩn
  DateTime _getDateTimeChuan(MonHoc mon) {
    try {
      // Tách chuỗi "07:30"
      final parts = mon.thoiGian.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      // Gộp với ngày học
      return DateTime(
        mon.ngayHoc.year,
        mon.ngayHoc.month,
        mon.ngayHoc.day,
        hour,
        minute,
      );
    } catch (e) {
      return mon.ngayHoc; // Nếu lỗi format giờ thì trả về ngày gốc (00:00)
    }
  }

  //--- 1. Đọc dữ liệu từ ổ cứng ---
  Future<void> loadData() async {
    _danhSach = await DatabaseHelper.instance.readAll();
  }


  //--- 2. Thêm môn ---
  Future<void> themMon(MonHoc mon) async {
    //Lưu xuống sql -> Nó trả về cái ID mới sinh ra
    int idMoi = await DatabaseHelper.instance.create(mon);
    mon.id = idMoi; // Gán ID đó vào object trên RAM
    _danhSach.add(mon); //Thêm vào list hiển thị
    _sapXepListHienThi();

    //Hẹn giờ thông báo
     await NotificationHelper.henGioBaoThuc(
      id: idMoi, // Dùng ID của database làm ID thông báo luôn (thông minh chưa!)
      title: "Sắp đến giờ học: ${mon.tenMon}",
      body: "Phòng: ${mon.phongHoc} | Giờ: ${mon.thoiGian}",
      thoiGianHoc: _getDateTimeChuan(mon),
    );
  }

  //--- 3. Xóa môn ---
  Future<void> xoaMon(MonHoc mon) async {
    if (mon.id != null) {
      await DatabaseHelper.instance.delete(mon.id!); //Xóa trong DB
      _danhSach.remove(mon); // Xóa trên RAM

      // Hủy thông báo tương ứng
      await NotificationHelper.huyNhacNho(mon.id!);
    }
  }

  //--- 5. Sửa môn ---
  Future<void> suaMon(MonHoc monCu, MonHoc monMoi) async {
    monMoi.id = monCu.id;

    await DatabaseHelper.instance.update(monMoi); //Update DB

    //Update trên RAM
    int index =_danhSach.indexOf(monCu);
    if (index != -1) {
      _danhSach[index] = monMoi;
      _sapXepListHienThi();

      //Sửa thông báo cũ
      if (monCu.id != null) {
        await NotificationHelper.huyNhacNho(monCu.id!);
        await NotificationHelper.henGioBaoThuc(
          id: monCu.id!,
          title: "Sắp đến giờ học: ${monMoi.tenMon}",
          body: "Phòng: ${monMoi.phongHoc} | Giờ: ${monMoi.thoiGian}",
          thoiGianHoc: _getDateTimeChuan(monMoi),
        );
      }
    }
  }

  //Hàm làm mới (Xóa hết rồi nạp lại)
  Future<void> lamMoiDanhSach(List<MonHoc> listMoi) async {
    for (var m in _danhSach) {
      if (m.id != null) await DatabaseHelper.instance.delete(m.id!); //Xóa từng cái cho an toàn
    }
    _danhSach.clear();

    //Thêm mới
    for (var m in listMoi) {
      await themMon(m);
    }
  }


 //Hàm sắp xếp nội bộ trên RAM (cập nhật giao diện)
  void _sapXepListHienThi() {
    _danhSach.sort((a, b) {
      int cmp = a.ngayHoc.compareTo(b.ngayHoc);
      if (cmp != 0) return cmp;
      return a.thoiGian.compareTo(b.thoiGian);
    });
  }

}
