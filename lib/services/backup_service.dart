import 'dart:convert'; //Đổi file sang json các kiểu
import 'dart:io'; //Thao tác với class File (đọc / ghi file vật lý)
import 'package:file_picker/file_picker.dart'; //Mở hộp thoại chọn file trên máy, upload file,...
import 'package:flutter/material.dart'; //UI
import 'package:intl/intl.dart'; //Format ngày giờ số để đặt tên file
import 'package:path_provider/path_provider.dart'; //Để tìm đường dẫn thư mục tạm (Cache)
import 'package:share_plus/share_plus.dart'; //Chia sẻ nội dung ra ngoài app
import '../models/mon_hoc.dart'; //Có cái này để dùng toJson với fromJson các kiểu
import 'danh_sach_service.dart'; //Dùng các dịch vụ liên quan tới danh sách lịch


class BackupService {
  //SAO LƯU: Biến danh sách thành file JSON và gửi đi
  //static: để gọi trực tiếp BackupService.taoBanSaoLuu() mà không cần tạo object mới
  static Future<void> taoBanSaoLuu(BuildContext context, List<MonHoc> danhSach) async {
    try {
      if (danhSach.isEmpty) {
        //Nếu dan sách rỗng thì hiện thông báo rồi thoát
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Danh sách trống, không có gì để lưu!")),
        );
        return;
      }

      //Chuyển danh sách thành chuỗi JSON
      //jsonEncode: hàm biến dữ liệu List/Map thành chuỗi String
      String dataJson = jsonEncode(danhSach.map((e) {
        //E là một MonHoc. e.toJson biến nó thành Map (Key-value)
        var map = e.toJson();
        map.remove('id'); //Bỏ trường ID ra khỏi map
        return map; //Trả về map cho phần tử này
      }).toList()); //jsonEncode cần List. map(...) trả về iterable nên cần toList
      //object từ danh sách -> Dùng map chuyển sang dạng json rồi tổng hợp thành List -> List được chuyển thành chuỗi Json lưu vào dataJson

      //Tạo tên file theo ngày giờ (VD: backup_22-12-2025_15-30.json)
      String timeStamp = DateFormat('dd-MM-yyyy_HH-mm').format(DateTime.now());
      String fileName = 'backup_SIVI_$timeStamp.json';

      
      //Lưu tạm vào thư mục cache của ứng dụng TODO: ASK
      //Tìm thư mục tạm (Cache của điện thoại)
      final directory = await getTemporaryDirectory();

      //Tào đường dẫn file vật lý
      final file = File('${directory.path}/$fileName');

      //Ghi chuỗi JSON vào file đó
      await file.writeAsString(dataJson);

      //Đóng gói file vào chuẩn XFile (chuẩn chung của Flutter cho đa nền tảng)
      final xFile = XFile(file.path);


      //Gọi SharePlus: bật cái bảng của Android lên (Zalo, Drive,...)
      //shareXFiles: chia sẻ file
      final result = await Share.shareXFiles(
        [xFile], //Danh sách file cần gửi
        text: 'File sao lưu lịch học SIVI', //Nội dung kèm theo
        subject: 'Sao lưu dữ liệu',
      );

      //Kiểm tra đã chia sẻ thành công chưa
      if (result.status == ShareResultStatus.success) {
          print("Đã chia sẻ thành công!");   
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã gửi file backup thành công!")),
            );
          }
        }

    } catch (e) {
      //Có lỗi thì hiện thông báo
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi sao lưu: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }


  //KHÔI PHỤC: Lấy file json, đọc dữ liệu, xóa DB cũ, nạp DB mới
  // nhận vào service để gọi hàm lamMoiDanhDach, onSuccess để báo cho UI vẽ lại TODO: Hỏi lại onSuc
  static Future<void> khoiPhucDuLieu(BuildContext context, DanhSachService service, Function onSuccess) async {
    try {
      // Mở trình chọn file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, //Chọn kiểu tùy chỉnh TODO:ASK
        allowedExtensions: ['json', 'txt'] //Chỉ cho chọn file json hoặc txt
      );

      //Nếu có chọn file (result không null)
      if (result != null) {
        //Lấy đường dẫn file được chọn
        File file = File(result.files.single.path!);

        //Đọc nội dung file thành chuỗi String
        String content = await file.readAsString();
        
        //Giải mã: String -> List<Map> (dynamic)
        List<dynamic> jsonList = jsonDecode(content);

        //Biến đổi: List<Map> -> List<MonHoc>
        List<MonHoc> listMoi = jsonList.map((e) => MonHoc.fromJson(e)).toList();

        //Hỏi xác nhận
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Cảnh báo khôi phục"),
              content: Text("Hành động này sẽ XÓA SẠCH dữ liệu hiện tại và thay thế bằng ${listMoi.length} môn học từ file backup.\n\nBạn có chắc chắn không?"),

              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Thôi")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx); //Đóng bảng hỏi

                    //Gọi Service để nạp dữ liệu mới
                    await service.lamMoiDanhSach(listMoi);

                    //Báo thành công và gọi hàm vẽ lại màn hình
                    onSuccess();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Khôi phục thành công!"), backgroundColor: Colors.green),
                      );
                    }
                  },
                  child: const Text("Khôi phục ngay"),
                )
              ],
            )
          );
        }
      }
    } catch (e) {
      //Nếu file bị lỗi format hay chọn nhầm file không phải JSON của app
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("File lỗi hoặc sai định dạng! ($e)"), backgroundColor: Colors.red),
        );
      }
    }
  }


}