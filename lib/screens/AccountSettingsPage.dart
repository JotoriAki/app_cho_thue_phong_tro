import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cho_thue_phong_tro/screens/api/api.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'N/A';
      _avatarUrl = prefs.getString('avatarUrl') ?? '';
      _isLoading = false;
    });
  }

  // Hàm cập nhật avatar
  Future<void> _updateAvatar(String newAvatarUrl) async {
    final url = 'http://${Api.baseUrl}:8000/api/user/upload';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';

    // In ra token lấy được
    print('Token: $token');

    if (token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không tìm thấy token')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'avt': newAvatarUrl}),
      );

      if (response.statusCode == 200) {
        await prefs.setString('avatarUrl', newAvatarUrl);
        setState(() {
          _avatarUrl = newAvatarUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật avatar thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi khi cập nhật avatar: ${response.statusCode} - ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi gọi API: $e')));
    }
  }

  // Hàm hiển thị popup cập nhật avatar
  void _showUpdateAvatarDialog() {
    final avatarController = TextEditingController(text: _avatarUrl);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cập nhật Avatar'),
            content: TextField(
              controller: avatarController,
              decoration: const InputDecoration(
                labelText: 'URL hình ảnh',
                hintText: 'Dán link hình ảnh tại đây',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  final newAvatarUrl = avatarController.text.trim();
                  if (newAvatarUrl.isNotEmpty && _isValidUrl(newAvatarUrl)) {
                    Navigator.pop(context);
                    await _updateAvatar(newAvatarUrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập URL hợp lệ')),
                    );
                  }
                },
                child: const Text('Cập nhật'),
              ),
            ],
          ),
    );
  }

  // Hàm kiểm tra URL hợp lệ
  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  // Hàm cập nhật mật khẩu
  Future<void> _changePassword(
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final url = 'http://${Api.baseUrl}:8000/api/user/changepassword';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không tìm thấy token')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Đổi mật khẩu thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Lỗi khi đổi mật khẩu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi gọi API: $e')));
    }
  }

  // Hàm hiển thị popup đổi mật khẩu
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                    ),
                    obscureText: true,
                  ),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                    ),
                    obscureText: true,
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
                  final oldPassword = oldPasswordController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();

                  if (oldPassword.isEmpty ||
                      newPassword.isEmpty ||
                      confirmPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng điền đầy đủ các trường'),
                      ),
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu mới không khớp')),
                    );
                    return;
                  }

                  if (newPassword.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mật khẩu mới phải có ít nhất 6 ký tự'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  await _changePassword(
                    oldPassword,
                    newPassword,
                    confirmPassword,
                  );
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt tài khoản'),
        backgroundColor: Colors.yellow[700],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _showUpdateAvatarDialog,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                            _avatarUrl != null && _isValidUrl(_avatarUrl!)
                                ? NetworkImage(_avatarUrl!)
                                : null,
                        child:
                            _avatarUrl == null || !_isValidUrl(_avatarUrl!)
                                ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Thay đổi mật khẩu'),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
    );
  }
}
