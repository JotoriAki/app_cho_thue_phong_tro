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
    print(
      'isLoggedIn: $isLoggedIn, username: $username, avatar: $avatar, email: $email',
    );
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
        print('Lỗi server: ${response.statusCode} - ${response.body}');
        return {'available': 0, 'rented': 0};
      }
    } catch (e) {
      print('Lỗi khi gọi API: $e');
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
    print('Bắt đầu gọi fetchAndSaveUserData');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    print('Token: $token');

    if (token == null || token.isEmpty) {
      print('Không tìm thấy token. Không thể gọi API.');
      return;
    }

    final url = 'http://${Api.baseUrl}:8000/api/user/token';
    print('URL API: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Trạng thái API: ${response.statusCode}');
      print('Dữ liệu thô từ API: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Dữ liệu parsed từ API: $data');

        await prefs.setString('userId', data['_id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setString('avatar', data['avt'] ?? '');

        print('Thông tin user đã được lưu thành công.');
        print('Username lưu: ${prefs.getString('username')}');
      } else {
        print('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi gọi API: $e');
    }
  }

  Future<void> sendEmail(
    String userEmail,
    String subject,
    String content,
  ) async {
    // Thay bằng email và App Password của bạn
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
      final sendReport = await send(message, smtpServer);
      print('Email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending email: $e');
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
            print('Lỗi trong FutureBuilder: ${snapshot.error}');
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: 80,
                        height: 120,
                        child: CircleAvatar(
                          radius: 50,
                          child: ClipOval(
                            child: Image.network(
                              isLoggedIn && (avatar != null && avatar.isNotEmpty) ? avatar : defaultAvatar,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Lỗi tải avatar: $error');
                                return const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
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
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      color: const Color.fromARGB(255, 233, 233, 233),
                      width: MediaQuery.of(context).size.width,
                      child: const Text(
                        'Quản lí phòng trọ',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
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
                              MaterialPageRoute(builder: (context) => QlTin()),
                            );
                          }
                          : null,
                ),
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
                              MaterialPageRoute(builder: (context) => QlTin()),
                            );
                          }
                          : null,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      color: const Color.fromARGB(255, 233, 233, 233),
                      width: MediaQuery.of(context).size.width,
                      child: const Text(
                        'Tiện ích',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                buildMenuItem(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      color: const Color.fromARGB(255, 233, 233, 233),
                      width: MediaQuery.of(context).size.width,
                      child: const Text(
                        'Tài khoản',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
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
                                    (context) => const AccountSettingsPage(),
                              ),
                            );
                          }
                          : null,
                ),
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
                                        onPressed: () => Navigator.pop(context),
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
          );
        },
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
    return Container(
      padding: const EdgeInsets.all(5),
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              padding: const EdgeInsets.all(5),
              child: Icon(icon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: onTap != null ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
