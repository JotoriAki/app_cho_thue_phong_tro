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
  PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    _pageController.dispose();
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
          });
        } else {
          setState(() {
            _savedRoomIds = [];
          });
        }
      } else {
        setState(() {
          _savedRoomIds = [];
        });
      }
    } catch (e) {
      setState(() {
        _savedRoomIds = [];
      });
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
            SnackBar(content: Text('Lỗi bỏ lưu: ${response.statusCode}')),
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
            SnackBar(content: Text('Lỗi lưu tin: ${response.statusCode}')),
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
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            'Chi tiết phòng trọ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.yellow[700],
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _savedRoomIds.contains(widget.roomId)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                color: Colors.white,
              ),
              onPressed: () => toggleSaveRoom(widget.roomId),
            ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Carousel
                          _buildImageCarousel(),
                          const SizedBox(height: 16),
                          // Main Info Card
                          _buildMainInfoCard(),
                          const SizedBox(height: 16),
                          // Details Card
                          _buildDetailsCard(),
                          const SizedBox(height: 16),
                          // Utilities Card
                          if (_roomData!['utilities'] != null &&
                              _roomData!['utilities'].isNotEmpty)
                            _buildUtilitiesCard(),
                          const SizedBox(height: 16),
                          // Description Card
                          _buildDescriptionCard(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 250,
              child:
                  _roomData!['images'] != null &&
                          _roomData!['images'].isNotEmpty
                      ? PageView.builder(
                        controller: _pageController,
                        itemCount: _roomData!['images'].length,
                        itemBuilder: (context, index) {
                          final imageUrl = _roomData!['images'][index];
                          return isValidUrl(imageUrl)
                              ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  return progress == null
                                      ? child
                                      : Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
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
                                color: Colors.grey[200],
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
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
            ),
            // Image Counter
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${_roomData!['images']?.length ?? 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _roomData!['title'] ?? 'Không có tiêu đề',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _roomData!['price'] != null
                ? '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_roomData!['price'])}/Tháng'
                : 'Không có giá',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _roomData!['address'] ?? 'Không xác định',
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.square_foot,
            label: 'Diện tích',
            value: '${_roomData!['area'] ?? 'N/A'} m²',
          ),
          const Divider(height: 16),
          _buildDetailRow(
            icon: Icons.category,
            label: 'Loại',
            value: _roomData!['type'] ?? 'N/A',
          ),
          const Divider(height: 16),
          _buildDetailRow(
            icon: Icons.check_circle_outline,
            label: 'Trạng thái',
            value:
                _roomData!['status'] == 'available'
                    ? 'Còn trống'
                    : 'Đã cho thuê',
          ),
          const Divider(height: 16),
          _buildDetailRow(
            icon: Icons.person_outline,
            label: 'Người đăng',
            value: _roomData!['postedBy'] ?? 'N/A',
          ),
          const Divider(height: 16),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Ngày đăng',
            value:
                _roomData!['createdAt'] != null
                    ? DateFormat(
                      'dd/MM/yyyy',
                    ).format(DateTime.parse(_roomData!['createdAt']))
                    : 'N/A',
          ),
          const Divider(height: 16),
          _buildDetailRow(
            icon: Icons.phone,
            label: 'Số điện thoại',
            value: _roomData!['phone'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildUtilitiesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                (_roomData!['utilities'] as List).map((utility) {
                  return Chip(
                    label: Text(utility, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.yellow[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.yellow[200]!),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _roomData!['description'] ?? 'Không có mô tả',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
