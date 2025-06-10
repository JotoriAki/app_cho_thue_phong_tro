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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = "";
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _pages = [
    HomePage(),
    HomePage(), // HomePage chiếm 2 vị trí
    DangTin(userName: ""),
    QlTin(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) async {
    // Animation cho button press
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

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

Future<void> _loadUserName() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _userName = prefs.getString('userName') ?? "";
    _pages[2] = DangTin(userName: _userName);
  });
}

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isCenter = false,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      flex: isCenter ? 2 : 1,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: GestureDetector(
              onTap: () => _onItemTapped(index),
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isCenter ? 4 : 1,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isCenter ? 25 : 20),
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isCenter
                              ? [
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFFA500),
                                ]
                              : [
                                  const Color(0xFFFF6B35),
                                  const Color(0xFFFF8E53),
                                ],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isCenter ? Colors.amber : Colors.orange)
                                .withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCenter && index == 2)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.black87,
                          size: 18,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : Colors.transparent,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: isSelected ? 20 : 18,
                        ),
                      ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? (isCenter ? Colors.black87 : Colors.white)
                            : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FA),
              Color(0xFFFFFFFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomAppBar(
            color: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                  icon: Icons.home_rounded,
                  label: "Trang chủ",
                  index: 0,
                  isCenter: _selectedIndex == 0,
                  ),
                  _buildNavItem(
                  icon: Icons.edit_rounded,
                  label: "Đăng tin trọ",
                  index: 2,
                  isCenter: _selectedIndex == 2,
                  ),
                  _buildNavItem(
                  icon: Icons.list_alt_rounded,
                  label: "Quản lý trọ",
                  index: 3,
                  isCenter: _selectedIndex == 3,
                  ),
                  _buildNavItem(
                  icon: Icons.person_rounded,
                  label: "Tài khoản",
                  index: 4,
                  isCenter: _selectedIndex == 4,
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      );
  }
}
