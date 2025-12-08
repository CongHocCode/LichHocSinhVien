// lib/models/mon_hoc.dart

class MonHoc {
  String tenMon;
  String phongHoc;
  String thoiGian;
  String ghiChu;

  MonHoc({
    required this.tenMon,
    required this.phongHoc,
    required this.thoiGian,
    this.ghiChu = "",
  });

  //Ham bien object thanh Map (chuyen thanh json) TOASK
  Map<String, dynamic> toJson() {
    return {
      'tenMon' : tenMon,
      'phongHoc': phongHoc,
      'thoiGian' : thoiGian,
      'ghiChu' : ghiChu,
    };
  }

  //Ham bien Map thanh Object de doc du lieu TOASK
  factory MonHoc.fromJson(Map<String, dynamic> json) {
    return MonHoc(
      tenMon: json['tenMon'],
      phongHoc: json['phongHoc'],
      thoiGian: json['thoiGian'],
      ghiChu: json['ghiChu'] ?? "", //null thi lay rong
    );
  }
}