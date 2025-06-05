import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:flutter/material.dart';
import 'package:app_cho_thue_phong_tro/screens/LoginPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:app_cho_thue_phong_tro/screens/RoomDetailPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<String> _savedRoomIds = [];
  List<dynamic> _phongTroData = [];
  List<dynamic> _filteredPhongTroData = [];
  bool _isLoading = true;
  String? _selectedDistrict = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true; // Hiển thị loading khi bắt đầu tải dữ liệu
    });
    try {
      await Future.wait([fetchPhongTroData(), fetchSavedRooms()]);
    } catch (e) {
      print('Lỗi khi tải dữ liệu: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
    } finally {
      setState(() {
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
    }
  }

  Future<void> fetchPhongTroData() async {
    final url = 'http://${Api.baseUrl}:8000/api/phongtro/getAll';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _phongTroData = data;
          _filteredPhongTroData = data;
          if (_selectedDistrict != 'Tất cả') {
            filterRoomsByDistrict(_selectedDistrict);
          }
        });
      } else {
        print('Lỗi server getAll: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi gọi API getAll: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else if (index == 3) {
      // TODO: Chuyển đến màn hình khác nếu cần
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

  String extractDistrict(String? address) {
    if (address == null || address.isEmpty) {
      return 'Không xác định';
    }
    final parts = address.split(', ');
    if (parts.length >= 2) {
      return parts[parts.length - 2];
    }
    return 'Không xác định';
  }

  List<String> getDistricts() {
    final districts =
        _phongTroData
            .map((item) => extractDistrict(item['address']))
            .toSet()
            .toList();
    districts.sort();
    return ['Tất cả', ...districts];
  }

  void filterRoomsByDistrict(String? district) {
    setState(() {
      _selectedDistrict = district;
      if (district == null || district == 'Tất cả') {
        _filteredPhongTroData = _phongTroData;
      } else {
        _filteredPhongTroData =
            _phongTroData
                .where((item) => extractDistrict(item['address']) == district)
                .toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ'),
        backgroundColor: Colors.yellow[700],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData, // Gọi _loadData khi kéo để làm mới
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Đảm bảo luôn có thể kéo
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        color: Colors.yellow[700],
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                value: _selectedDistrict,
                                hint: const Text('Chọn quận'),
                                isExpanded: true,
                                items:
                                    getDistricts().map((String district) {
                                      return DropdownMenuItem<String>(
                                        value: district,
                                        child: Text(district),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  filterRoomsByDistrict(newValue);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "Chợ Tốt Có Gì Mới?",
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
                            for (var item in _filteredPhongTroData)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RoomDetailPage(
                                            roomId: item['_id'],
                                          ),
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
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              height: 80,
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          },
                        )
                        : Container(
                          height: 80,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.black,
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
                    color: Colors.yellow[700],
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
