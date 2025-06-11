import 'dart:convert';
import 'package:app_cho_thue_phong_tro/screens/AccountSettingsPage.dart';
import 'package:http/http.dart' as http;
import 'package:app_cho_thue_phong_tro/main.dart';
import 'package:app_cho_thue_phong_tro/screens/LoginPage.dart';
import 'package:app_cho_thue_phong_tro/screens/SavedRoomsPage.dart';
import 'package:app_cho_thue_phong_tro/screens/QlTin.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Profile extends StatelessWidget {
  static const String defaultAvatar =
      'https://dongvat.edu.vn/upload/2024/12/avatar-cute-chibi-12.webp';

  const Profile({super.key});

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final username = prefs.getString('username') ?? 'Đăng nhập / Đăng ký';
    final avatar = prefs.getString('avatar') ?? defaultAvatar;
    final email = prefs.getString('email') ?? '';
    return {
      'isLoggedIn': isLoggedIn,
      'username': username,
      'avatar': avatar,
      'email': email,
    };
  }

  Future<Map<String, int>> fetchRoomCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final username = prefs.getString('username') ?? '';

    if (!isLoggedIn || username.isEmpty) {
      return {'available': 0, 'rented': 0};
    }

    final url = 'http://${Api.baseUrl}:8000/api/phongtro/getByActor';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> posts = json.decode(response.body);
        final availableCount =
            posts.where((post) => post['status'] == 'available').length;
        final rentedCount =
            posts.where((post) => post['status'] == 'rented').length;
        return {'available': availableCount, 'rented': rentedCount};
      } else {
        return {'available': 0, 'rented': 0};
      }
    } catch (e) {
      return {'available': 0, 'rented': 0};
    }
  }

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MyApp()),
      (route) => false,
    );
  }

  Future<void> fetchAndSaveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token == null || token.isEmpty) return;

    final url = 'http://${Api.baseUrl}:8000/api/user/token';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        await prefs.setString('userId', data['_id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setString('avatar', data['avt'] ?? '');
      }
    } catch (e) {}
  }

  Future<void> sendEmail(
    String userEmail,
    String subject,
    String content,
  ) async {
    const String smtpEmail = 'thientan2408@gmail.com';
    const String smtpPassword = 'dspw eayp dzze yrpj';

    final smtpServer = gmail(smtpEmail, smtpPassword);

    final message =
        Message()
          ..from = Address(userEmail, 'Người dùng ứng dụng')
          ..recipients.add('thientan1223@gmail.com')
          ..subject = subject
          ..text = content;

    try {
      await send(message, smtpServer);
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  void showFeedbackDialog(BuildContext context, String userEmail) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đóng góp ý kiến'),
            content: TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Nhập ý kiến của bạn...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  final feedback = feedbackController.text.trim();
                  if (feedback.isNotEmpty) {
                    try {
                      await sendEmail(
                        userEmail,
                        'Đóng góp ý kiến về ứng dụng Phòng trọ',
                        feedback,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ý kiến đã được gửi thành công!'),
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gửi ý kiến thất bại: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập ý kiến trước khi gửi.'),
                      ),
                    );
                  }
                },
                child: const Text('Gửi'),
              ),
            ],
          ),
    );
  }

  void showHelpDialog(BuildContext context, String userEmail) {
    final TextEditingController helpController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Trợ giúp'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Câu hỏi thường gặp (FAQ):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    title: const Text('Làm thế nào để đăng tin phòng trọ?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Để đăng tin, bạn cần đăng nhập, sau đó chọn mục "Đăng tin trọ" từ thanh điều hướng dưới cùng. Điền đầy đủ thông tin phòng trọ và nhấn "Đăng tin".',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Làm sao để quản lý các tin đã đăng?'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Vào mục "Quản lý trọ" từ thanh điều hướng để xem, chỉnh sửa hoặc xóa các tin đăng của bạn.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      'Tôi muốn đổi mật khẩu thì phải làm sao?',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Tại giao diện hãy nhấn vào mục "Tài Khoản" và bấm vào "Cài Đặt Tài Khoản" sau đó bấm "thay đổi mật khẩu" và làm theo hướng dẫn',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cần hỗ trợ thêm?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: helpController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Mô tả vấn đề bạn cần hỗ trợ...',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
                  final helpText = helpController.text.trim();
                  if (helpText.isNotEmpty) {
                    try {
                      await sendEmail(
                        userEmail,
                        'Yêu cầu hỗ trợ từ ứng dụng Phòng trọ',
                        helpText,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yêu cầu hỗ trợ đã được gửi!'),
                        ),
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gửi yêu cầu thất bại: $e')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng mô tả vấn đề trước khi gửi.'),
                      ),
                    );
                  }
                },
                child: const Text('Gửi'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          getUserData().then((userData) => {'userData': userData}),
          fetchRoomCounts().then((counts) => {'roomCounts': counts}),
        ]).then((results) {
          final userData = results[0]['userData'] as Map<String, dynamic>;
          final roomCounts = results[1]['roomCounts'] as Map<String, int>;
          return {
            'isLoggedIn': userData['isLoggedIn'],
            'username': userData['username'],
            'avatar': userData['avatar'],
            'email': userData['email'],
            'availableCount': roomCounts['available'],
            'rentedCount': roomCounts['rented'],
          };
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi, vui lòng thử lại'));
          }

          final isLoggedIn = snapshot.data?['isLoggedIn'] ?? false;
          final username = snapshot.data?['username'] ?? 'Đăng nhập / Đăng ký';
          final avatar = snapshot.data?['avatar'] ?? defaultAvatar;
          final email = snapshot.data?['email'] ?? '';
          final availableCount = snapshot.data?['availableCount'] ?? 0;
          final rentedCount = snapshot.data?['rentedCount'] ?? 0;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with gradient background
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 216, 23),
                        Color.fromARGB(255, 253, 255, 151),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 42,
                          backgroundImage: NetworkImage(
                            isLoggedIn && (avatar != null && avatar.isNotEmpty)
                                ? avatar
                                : defaultAvatar,
                          ),
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isLoggedIn ? email : 'Chạm để đăng nhập',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Card: Quản lý phòng trọ
                _sectionTitle('Quản lí phòng trọ'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        buildMenuItem(
                          context,
                          icon: Icons.home,
                          color: Colors.blue,
                          text: 'Phòng trọ còn trống: $availableCount',
                          onTap:
                              isLoggedIn
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QlTin(),
                                      ),
                                    );
                                  }
                                  : null,
                        ),
                        const Divider(height: 1),
                        buildMenuItem(
                          context,
                          icon: Icons.meeting_room,
                          color: Colors.green,
                          text: 'Phòng trọ đã cho thuê: $rentedCount',
                          onTap:
                              isLoggedIn
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QlTin(),
                                      ),
                                    );
                                  }
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
                // Card: Tiện ích
                _sectionTitle('Tiện ích'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: buildMenuItem(
                    context,
                    icon: Icons.bookmark,
                    color: Colors.purple,
                    text: 'Tin đăng đã lưu',
                    onTap:
                        isLoggedIn
                            ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SavedRoomsPage(),
                                ),
                              );
                            }
                            : null,
                  ),
                ),
                // Card: Tài khoản
                _sectionTitle('Tài khoản'),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      buildMenuItem(
                        context,
                        icon: Icons.settings,
                        color: Colors.blue,
                        text: 'Cài đặt tài khoản',
                        onTap:
                            isLoggedIn
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const AccountSettingsPage(),
                                    ),
                                  );
                                }
                                : null,
                      ),
                      const Divider(height: 1),
                      buildMenuItem(
                        context,
                        icon: Icons.help,
                        color: Colors.orange,
                        text: 'Trợ giúp',
                        onTap:
                            isLoggedIn
                                ? () {
                                  showHelpDialog(context, email);
                                }
                                : null,
                      ),
                      const Divider(height: 1),
                      buildMenuItem(
                        context,
                        icon: Icons.feedback,
                        color: Colors.green,
                        text: 'Đóng góp ý kiến',
                        onTap:
                            isLoggedIn
                                ? () {
                                  showFeedbackDialog(context, email);
                                }
                                : null,
                      ),
                      const Divider(height: 1),
                      buildMenuItem(
                        context,
                        icon: Icons.logout,
                        color: Colors.red,
                        text: 'Đăng xuất',
                        onTap:
                            isLoggedIn
                                ? () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Xác nhận'),
                                          content: const Text(
                                            'Bạn có chắc chắn muốn đăng xuất không?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                logout(context);
                                              },
                                              child: const Text('Đăng xuất'),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                                : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 18, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F8FFF),
          ),
        ),
      ),
    );
  }

  Widget buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(onTap != null ? 1 : 0.3),
                boxShadow:
                    onTap != null
                        ? [
                          BoxShadow(
                            color: color.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: onTap != null ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}
