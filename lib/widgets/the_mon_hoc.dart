import 'package:flutter/material.dart';
import '../models/mon_hoc.dart';


class TheMonHoc extends StatelessWidget {
  final MonHoc monHoc;
  final VoidCallback onBamVao; //Ham xu ly khi bam vao

  
  const TheMonHoc({
    super.key,
    required this.monHoc,
    required this.onBamVao,
  });

  @override
 Widget build(BuildContext context) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 5, //Chỉnh bóng đổ

    //Một dòng của danh sách các môn học trong thời khóa biểu trông như sau
    child: ListTile(
      //Lấy chữ cái đầu của tên môn làm avt
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,

        child: Text(
          monHoc.tenMon.isNotEmpty ? monHoc.tenMon[0].toUpperCase() : "?", //Xử lý trường hợp tên môn trống
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ), 

      title: Text(
        monHoc.tenMon,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(monHoc.thoiGian),
            const SizedBox(width: 10),
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(monHoc.phongHoc),
          ],
        ),
      ),

      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onBamVao,

    ),
  );



 }


}