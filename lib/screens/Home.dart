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
      _isLoading = true;
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
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Trang Chủ',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF222222)),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.yellow[700]!, Colors.orange[300]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow[700]!.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.07),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: DropdownButton<String>(
                                      value: _selectedDistrict,
                                      hint: const Text('Chọn quận'),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down),
                                      items: getDistricts().map((String district) {
                                        return DropdownMenuItem<String>(
                                          value: district,
                                          child: Text(
                                            district,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        filterRoomsByDistrict(newValue);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(Icons.search, color: Colors.yellow[700], size: 30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Section title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            "Chợ Tốt Có Gì Mới?",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.builder(
                        itemCount: _filteredPhongTroData.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 2.7,
                        ),
                        itemBuilder: (context, index) {
                          final item = _filteredPhongTroData[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomDetailPage(
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
                              item['images'] != null && item['images'].isNotEmpty
                                  ? item['images'][0]
                                  : 'assets/placeholder.jpg',
                              item['_id'] ?? '',
                              item['address'] ?? 'Không xác định',
                              item['status'] ?? 'rented',
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.09),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(22),
                ),
                child: isValidUrl(imagePath)
                    ? Image.network(
                        imagePath,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            width: 120,
                            color: Colors.grey[200],
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
                        height: 120,
                        width: 120,
                        color: Colors.grey[200],
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
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => toggleSaveRoom(id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(7),
                    child: Icon(
                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: Colors.yellow[700],
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF222222),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          districtAndCity,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: status == 'available' ? Colors.green[600] : Colors.red[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status == 'available' ? 'Còn trống' : 'Đã cho thuê',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
