import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:app_cho_thue_phong_tro/screens/QlTin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditDetailPage extends StatefulWidget {
  final String roomId;
  final Future<void> Function()? onDataChanged; // Thêm tham số onDataChanged

  const EditDetailPage({super.key, required this.roomId, this.onDataChanged});

  @override
  _EditDetailPageState createState() => _EditDetailPageState();
}

class _EditDetailPageState extends State<EditDetailPage> {
  Map<String, dynamic>? _roomData;
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    print('Room ID: ${widget.roomId}'); // Gỡ lỗi roomId
    fetchRoomDetails();
  }

  Future<void> fetchRoomDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? "";
    if (userName.isEmpty) {
      setState(() {
        _errorMessage = 'Không tìm thấy tên người dùng.';
        _isLoading = false;
      });
      return;
    }
    _userName = userName;
    final url = 'http://${Api.baseUrl}:8000/api/phongtro/getById';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id': widget.roomId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _roomData = json.decode(response.body);
          _isLoading = false;
          print('Room data: $_roomData'); // Gỡ lỗi dữ liệu
        });
      } else {
        setState(() {
          _errorMessage =
              'Lỗi server: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi gọi API: $e';
        _isLoading = false;
      });
    }
  }

  // Hàm xóa bài đăng
  Future<void> deletePost() async {
    final url =
        'http://${Api.baseUrl}:8000/api/phongtro/delete/${widget.roomId}';
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài đăng thành công')),
        );
        if (widget.onDataChanged != null) {
          await widget.onDataChanged!(); // Gọi onDataChanged sau khi xóa
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const QlTin()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi xóa: ${response.statusCode} - ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi gọi API xóa: $e')));
    }
  }

  // Hàm xác nhận xóa
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text('Bạn có chắc muốn xóa bài đăng này không?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  // Hàm chỉnh sửa bài đăng
  Future<void> updatePost(Map<String, dynamic> updatedData) async {
    final url = 'http://${Api.baseUrl}:8000/api/phongtro/update';
    try {
      print(
        'Updating post with data: ${jsonEncode({'id': widget.roomId, ...updatedData})}',
      );
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': widget.roomId, ...updatedData}),
      );

      print('Update response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật bài đăng thành công')),
        );
        if (widget.onDataChanged != null) {
          await widget.onDataChanged!(); // Gọi onDataChanged sau khi cập nhật
        }
        await fetchRoomDetails(); // Làm mới dữ liệu
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi cập nhật: ${response.statusCode} - ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi gọi API cập nhật: $e')));
    }
  }

  // Hàm hiển thị popup chỉnh sửa
  void _showEditDialog() {
    final titleController = TextEditingController(
      text: _roomData!['title'] ?? '',
    );
    final priceController = TextEditingController(
      text: _roomData!['price']?.toString() ?? '',
    );
    final areaController = TextEditingController(
      text: _roomData!['area']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: _roomData!['address'] ?? '',
    ); // Thêm controller cho địa chỉ
    final descriptionController = TextEditingController(
      text: _roomData!['description'] ?? '',
    );
    final imageController = TextEditingController(
      text:
          _roomData!['images'] != null && _roomData!['images'].isNotEmpty
              ? _roomData!['images'][0]
              : '',
    );
    final phoneController = TextEditingController(
      text: _roomData!['phone']?.toString() ?? '',
    );

    final types = [
      'Phòng trọ thường',
      'Phòng trọ có gác',
      'Phòng trọ cao cấp',
      'Chung cư mini',
      'Nhà nguyên căn',
      'Căn hộ dịch vụ',
      'Căn hộ chung cư',
    ];

    List<String> selectedUtilities = List<String>.from(
      _roomData!['utilities'] ?? [],
    );

    final List<String> availableUtilities = [
      'Wi-Fi',
      'Điều hòa',
      'Máy giặt',
      'Tủ lạnh',
      'Bếp',
      'Bãi đỗ xe',
    ];

    String? selectedType = _roomData!['type'];
    if (!types.contains(selectedType)) {
      selectedType = 'Phòng trọ thường';
    }

    String? selectedStatus = _roomData!['status'] ?? 'available';
    final statuses = ['available', 'rented'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chỉnh sửa bài đăng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Giá (VND/tháng)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Diện tích (m²)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ',
                      ), // Thêm TextField cho địa chỉ
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Loại'),
                      items:
                          types.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                      items:
                          statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status == 'available'
                                    ? 'Còn trống'
                                    : 'Đã cho thuê',
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tiện ích:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          availableUtilities.map((utility) {
                            final isSelected = selectedUtilities.contains(
                              utility,
                            );
                            return FilterChip(
                              label: Text(utility),
                              selected: isSelected,
                              selectedColor: Colors.yellow[200],
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedUtilities.add(utility);
                                  } else {
                                    selectedUtilities.remove(utility);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(
                        labelText: 'URL hình ảnh',
                      ),
                    ),
                    Text(_userName),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    final updatedData = {
                      'title': titleController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'area': double.tryParse(areaController.text) ?? 0,
                      'address':
                          addressController
                              .text, // Thêm địa chỉ vào updatedData
                      'type': selectedType,
                      'status': selectedStatus,
                      'description': descriptionController.text,
                      'images':
                          imageController.text.isNotEmpty
                              ? [imageController.text]
                              : [],
                      'utilities': selectedUtilities,
                      'phone': phoneController.text,
                      'postedBy': _userName,
                    };
                    Navigator.pop(context);
                    await updatePost(updatedData);
                  },
                  child: const Text('Hoàn tất'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hàm kiểm tra URL hợp lệ
  bool isValidUrl(String? url) {
    return url != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          print('Nút quay lại được nhấn');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết phòng trọ'),
          backgroundColor: Colors.yellow[700],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hình ảnh
                      if (_roomData!['images'] != null &&
                          _roomData!['images'].isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child:
                              isValidUrl(_roomData!['images'][0])
                                  ? Image.network(
                                    _roomData!['images'][0],
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  : Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                        ),
                      const SizedBox(height: 16),

                      // Tiêu đề
                      Text(
                        _roomData!['title'] ?? 'Không có tiêu đề',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Giá
                      Text(
                        _roomData!['price'] != null
                            ? '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_roomData!['price'])}/Tháng'
                            : 'Không có giá',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Diện tích
                      Text(
                        'Diện tích: ${_roomData!['area'] ?? 'N/A'} m²',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Địa chỉ
                      Text(
                        'Địa chỉ: ${_roomData!['address'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Loại
                      Text(
                        'Loại: ${_roomData!['type'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Trạng thái
                      Text(
                        'Trạng thái: ${_roomData!['status'] == 'available' ? 'Còn trống' : 'Đã cho thuê'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Số điện thoại
                      Text(
                        'Số điện thoại: ${_roomData!['phone'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Tiện ích
                      if (_roomData!['utilities'] != null &&
                          _roomData!['utilities'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tiện ích:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: List<Widget>.from(
                                (_roomData!['utilities'] as List).map(
                                  (utility) => Chip(
                                    label: Text(utility),
                                    backgroundColor: Colors.yellow[100],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // Người đăng
                      Text(
                        'Người đăng: ${_roomData!['postedBy'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Ngày đăng
                      Text(
                        'Ngày đăng: ${_roomData!['createdAt'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_roomData!['createdAt'])) : 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Mô tả
                      const Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _roomData!['description'] ?? 'Không có mô tả',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Nút hành động
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showEditDialog,
                            icon: const Icon(Icons.edit, color: Colors.white),
                            label: const Text('Chỉnh sửa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _showDeleteConfirmation,
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text('Xóa bài đăng'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
