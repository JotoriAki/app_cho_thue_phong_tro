import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:app_cho_thue_phong_tro/screens/EditDetailPage.dart';

class QlTin extends StatefulWidget {
  final Future<void> Function()? onDataChanged;

  const QlTin({super.key, this.onDataChanged});

  @override
  State<QlTin> createState() => _QlTinState();
}

class _QlTinState extends State<QlTin> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String _userName = '';
  String _error = '';
  String _selectedFilter = 'all'; // Bộ lọc mặc định là "Tất cả"

  @override
  void initState() {
    super.initState();
    fetchQLTin();
  }

  Future<void> fetchQLTin() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? "";
      if (userName.isEmpty) {
        setState(() {
          _error = 'Vui lòng đăng nhập';
          _isLoading = false;
        });
        return;
      }
      _userName = userName;
      final url = 'http://${Api.baseUrl}:8000/api/phongtro/getByActor';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': _userName}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _posts = data is List ? data : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Lỗi server: ${response.statusCode} - ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Lỗi khi gọi API: $e';
        _isLoading = false;
      });
    }
  }

  bool isValidUrl(String? url) {
    return url != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  Future<void> _deletePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://${Api.baseUrl}:8000/api/phongtro/delete/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _posts.removeWhere((post) => post['_id'] == postId);
        });
        if (widget.onDataChanged != null) {
          await widget.onDataChanged!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa bài đăng thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
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
    // Lọc bài đăng dựa trên _selectedFilter
    final filteredPosts =
        _selectedFilter == 'all'
            ? _posts
            : _posts
                .where((post) => post['status'] == _selectedFilter)
                .toList();

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) {
          print('Nút quay lại được nhấn');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản Lý Trọ'),
          centerTitle: true,
          backgroundColor: Colors.yellow[700],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(child: Text(_error))
                : RefreshIndicator(
                  onRefresh: fetchQLTin,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          color: Colors.yellow[700],
                          child: DropdownButtonFormField<String>(
                            value: _selectedFilter,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Tất cả'),
                              ),
                              DropdownMenuItem(
                                value: 'rented',
                                child: Text('Đã cho thuê'),
                              ),
                              DropdownMenuItem(
                                value: 'available',
                                child: Text('Còn trống'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value!;
                              });
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Bài đăng của bạn",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        filteredPosts.isEmpty
                            ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'Không có bài đăng nào.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                            : Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                children: [
                                  for (var post in filteredPosts)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => EditDetailPage(
                                                  roomId: post['_id'],
                                                  onDataChanged:
                                                      widget.onDataChanged,
                                                ),
                                          ),
                                        ).then((_) async {
                                          await fetchQLTin();
                                          if (widget.onDataChanged != null) {
                                            await widget.onDataChanged!();
                                          }
                                        });
                                      },
                                      child: _buildRoomCard(
                                        post['title'] ?? 'Không có tiêu đề',
                                        post['price'] != null
                                            ? '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(post['price'])}/Tháng'
                                            : 'Không có giá',
                                        post['images'] != null &&
                                                post['images'].isNotEmpty
                                            ? post['images'][0]
                                            : 'assets/placeholder.jpg',
                                        post['_id'] ?? '',
                                        post['address'] ?? 'Không xác định',
                                        post['status'] ?? 'rented',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      ],
                    ),
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
