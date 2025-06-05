import 'package:app_cho_thue_phong_tro/screens/DangTin.dart';
import 'package:app_cho_thue_phong_tro/screens/Home.dart';
import 'package:app_cho_thue_phong_tro/screens/profile.dart';
import 'package:app_cho_thue_phong_tro/screens/QlTin.dart';
import 'package:app_cho_thue_phong_tro/screens/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Thuê Phòng Trọ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String _userName = "";

  final List<Widget> _pages = [
    HomePage(),
    HomePage(), // HomePage chiếm 2 vị trí
    DangTin(userName: ""),
    QlTin(),
    Profile(),
  ];

  void _onItemTapped(int index) async {
    if (index == 2) {
      // "Đăng tin trọ" ở index 2
      if (_userName.isEmpty) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );

        await _loadUserName();

        if (_userName.isNotEmpty) {
          setState(() {
            _pages[2] = DangTin(userName: _userName);
            _selectedIndex = index;
          });
        }
        return;
      } else {
        setState(() {
          _pages[2] = DangTin(userName: _userName);
          _selectedIndex = index;
        });
        return;
      }
    }

    setState(() {
      _selectedIndex =
          index == 1 ? 0 : index; // Index 1 chuyển về HomePage (index 0)
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "";
      _pages[2] = DangTin(userName: _userName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _onItemTapped(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home,
                        color:
                            _selectedIndex == 0 ? Colors.orange : Colors.grey,
                        size: 30,
                      ),
                      Text(
                        "Trang chủ",
                        style: TextStyle(
                          color:
                              _selectedIndex == 0 ? Colors.orange : Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Nút Đăng tin trọ (ở giữa)
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => _onItemTapped(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 39,
                        height: 39,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                      Text(
                        "Đăng tin trọ",
                        style: TextStyle(
                          color:
                              _selectedIndex == 2
                                  ? Colors.orange
                                  : const Color.fromRGBO(29, 27, 32, 1.0),
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Nút Quản lý trọ
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => _onItemTapped(3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.list,
                        color:
                            _selectedIndex == 3 ? Colors.orange : Colors.grey,
                        size: 30,
                      ),
                      Text(
                        "Quản lý trọ",
                        style: TextStyle(
                          color:
                              _selectedIndex == 3 ? Colors.orange : Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Nút Tài khoản
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () => _onItemTapped(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person,
                        color:
                            _selectedIndex == 4 ? Colors.orange : Colors.grey,
                        size: 30,
                      ),
                      Text(
                        "Tài khoản",
                        style: TextStyle(
                          color:
                              _selectedIndex == 4 ? Colors.orange : Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
