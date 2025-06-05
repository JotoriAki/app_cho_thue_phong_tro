import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomDetailPage extends StatefulWidget {
  final String roomId;

  const RoomDetailPage({super.key, required this.roomId});

  @override
  _RoomDetailPageState createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  Map<String, dynamic>? _roomData;
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _savedRoomIds = [];
  PageController _pageController = PageController(); // Controller cho PageView
  int _currentImageIndex = 0; // Chỉ số hình ảnh hiện tại

  @override
  void initState() {
    super.initState();
    _loadData();
    // Lắng nghe thay đổi trang để cập nhật chỉ số hình ảnh
    _pageController.addListener(() {
      int newIndex = _pageController.page!.round();
      if (newIndex != _currentImageIndex) {
        setState(() {
          _currentImageIndex = newIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Giải phóng PageController
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([fetchRoomDetails(), fetchSavedRooms()]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> fetchRoomDetails() async {
    final url = 'http://${Api.baseUrl}:8000/api/phongtro/getById';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': widget.roomId}),
      );
      print('Room ID: ${widget.roomId}');

      if (response.statusCode == 200) {
        setState(() {
          _roomData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi server: ${response.statusCode}';
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

  Future<void> fetchSavedRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';

    if (token.isEmpty) {
      setState(() {
        _savedRoomIds = [];
      });
      return;
    }

    final url = 'http://${Api.baseUrl}:8000/api/user/loadSaveRoom';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _savedRoomIds = List<String>.from(data['saveRoom'] ?? []);
            print('Danh sách phòng đã lưu: $_savedRoomIds');
          });
        } else {
          setState(() {
            _savedRoomIds = [];
          });
          print('API trả về success false');
        }
      } else {
        setState(() {
          _savedRoomIds = [];
        });
        print(
          'Lỗi server loadSaveRoom: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _savedRoomIds = [];
      });
      print('Lỗi khi gọi API loadSaveRoom: $e');
      _errorMessage = 'Lỗi khi tải danh sách phòng đã lưu';
    }
  }

  Future<void> toggleSaveRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để lưu tin')),
      );
      return;
    }

    final isSaved = _savedRoomIds.contains(roomId);

    if (isSaved) {
      final url = 'http://${Api.baseUrl}:8000/api/user/deleteSaveRoom';
      try {
        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'roomId': roomId}),
        );

        if (response.statusCode == 200) {
          setState(() {
            _savedRoomIds.remove(roomId);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Đã bỏ lưu tin')));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi bỏ lưu: ${response.statusCode} - ${response.body}',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    } else {
      final url = 'http://${Api.baseUrl}:8000/api/user/saveRoom';
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'roomId': roomId}),
        );

        if (response.statusCode == 200) {
          setState(() {
            _savedRoomIds.add(roomId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã lưu tin thành công')),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi lưu tin: ${response.statusCode} - ${response.body}',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
      }
    }
  }

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
          print('Back button pressed');
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
                      // Image Carousel
                      if (_roomData!['images'] != null &&
                          _roomData!['images'].isNotEmpty)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SizedBox(
                                height: 200,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: _roomData!['images'].length,
                                  itemBuilder: (context, index) {
                                    final imageUrl =
                                        _roomData!['images'][index];
                                    return isValidUrl(imageUrl)
                                        ? Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
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
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Dots Indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _roomData!['images'].length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _currentImageIndex == index
                                            ? Colors.yellow[700]
                                            : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        _roomData!['title'] ?? 'Không có tiêu đề',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Save Icon
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            _savedRoomIds.contains(widget.roomId)
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: Colors.yellow[700],
                          ),
                          onPressed: () {
                            toggleSaveRoom(widget.roomId);
                          },
                        ),
                      ),

                      // Price
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

                      // Address
                      Text(
                        'Địa chỉ: ${_roomData!['address'] ?? 'Không xác định'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Area
                      Text(
                        'Diện tích: ${_roomData!['area'] ?? 'N/A'} m²',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Type
                      Text(
                        'Loại: ${_roomData!['type'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Status
                      Text(
                        'Trạng thái: ${_roomData!['status'] == 'available' ? 'Còn trống' : 'Đã cho thuê'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Utilities
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

                      // Posted By
                      Text(
                        'Người đăng: ${_roomData!['postedBy'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),

                      // Created At
                      Text(
                        'Ngày đăng: ${_roomData!['createdAt'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_roomData!['createdAt'])) : 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      // Description
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

                      // Phone
                      Text(
                        'Số điện thoại: ${_roomData!['phone'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
      ),
    );
  }
}
