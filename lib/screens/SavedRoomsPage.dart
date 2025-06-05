import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:app_cho_thue_phong_tro/screens/RoomDetailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedRoomsPage extends StatefulWidget {
  const SavedRoomsPage({super.key});

  @override
  _SavedRoomsPageState createState() => _SavedRoomsPageState();
}

class _SavedRoomsPageState extends State<SavedRoomsPage> {
  List<String> _savedRoomIds = [];
  List<dynamic> _savedRoomsData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await fetchSavedRooms();
      if (_savedRoomIds.isNotEmpty) {
        await fetchSavedRoomsDetails();
      } else {
        setState(() {
          _savedRoomsData = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: $e';
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
        _isLoading = false;
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
          print('API loadSaveRoom trả về success false');
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
        _errorMessage = 'Lỗi khi gọi API loadSaveRoom: $e';
        _isLoading = false;
      });
      print('Lỗi khi gọi API loadSaveRoom: $e');
    }
  }

  Future<void> fetchSavedRoomsDetails() async {
    final url = 'http://${Api.baseUrl}:8000/api/phongtro/getPhongTroSave';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'roomIds': _savedRoomIds}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _savedRoomsData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Lỗi server getPhongTroSave: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
        print(
          'Lỗi server getPhongTroSave: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi gọi API getPhongTroSave: $e';
        _isLoading = false;
      });
      print('Lỗi khi gọi API getPhongTroSave: $e');
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
            _savedRoomsData.removeWhere((room) => room['_id'] == roomId);
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
            fetchSavedRoomsDetails();
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

  String extractDistrictAndCity(String? address) {
    if (address == null || address.isEmpty) {
      return 'Không xác định';
    }
    final parts = address.split(', ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]}, ${parts[parts.length - 1]}';
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin đăng đã lưu'),
        backgroundColor: Colors.yellow[700],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _savedRoomsData.isEmpty
              ? const Center(child: Text('Chưa có tin nào được lưu'))
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Tin đăng đã lưu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: [
                          for (var item in _savedRoomsData)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            RoomDetailPage(roomId: item['_id']),
                                  ),
                                );
                              },
                              child: _buildRoomCard(
                                item['title'] ?? 'Không có tiêu đề',
                                item['price'] != null
                                    ? '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(item['price'])}/Tháng'
                                    : 'Không có giá',
                                item['images'] != null &&
                                        item['images'].isNotEmpty
                                    ? item['images'][0]
                                    : 'assets/placeholder.jpg',
                                item['_id'] ?? '',
                                item['address'] ?? 'Không xác định',
                                item['status'] ?? 'rented',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildRoomCard(
    String title,
    String price,
    String imagePath,
    String id,
    String address,
    String status,
  ) {
    final isSaved = _savedRoomIds.contains(id);
    final districtAndCity = extractDistrictAndCity(address);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                child:
                    isValidUrl(imagePath)
                        ? Image.network(
                          imagePath,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 80,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                height: 80,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        )
                        : Container(
                          height: 80,
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
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.yellow[900],
                  ),
                  onPressed: () {
                    toggleSaveRoom(id);
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 14, color: Colors.red),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    districtAndCity,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    color: status == 'available' ? Colors.green : Colors.red,
                    child: Text(
                      status == 'available' ? 'Còn trống' : 'Đã cho thuê',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
