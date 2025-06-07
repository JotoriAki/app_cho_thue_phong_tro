import 'dart:convert';
import 'package:app_cho_thue_phong_tro/screens/api/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_cho_thue_phong_tro/main.dart';

class DangTin extends StatefulWidget {
  final String userName;

  const DangTin({super.key, required this.userName});

  @override
  State<DangTin> createState() => _DangTinState();
}

class _DangTinState extends State<DangTin> {
  String? selectedCategory;
  String? selectedType;
  List<String> selectedUtilities = [];
  List<String> imageUrls = [];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlsController = TextEditingController();

  final List<String> availableUtilities = [
    'Wi-Fi',
    'Điều hòa',
    'Máy giặt',
    'Tủ lạnh',
    'Bếp',
    'Bãi đỗ xe',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _imageUrlsController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  String? _validateImageUrls(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final urls =
        value.trim().split('\n').where((url) => url.trim().isNotEmpty).toList();
    if (urls.length > 6) return 'Tối đa 6 link hình ảnh';
    for (var url in urls) {
      if (!_isValidUrl(url.trim())) return 'Link không hợp lệ: $url';
    }
    return null;
  }

  void _updateImageUrls() {
    final text = _imageUrlsController.text.trim();
    setState(() {
      imageUrls =
          text.isEmpty
              ? []
              : text.split('\n').where((url) => url.trim().isNotEmpty).toList();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final postData = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "price": int.tryParse(_priceController.text) ?? 0,
      "area": int.tryParse(_areaController.text) ?? 0,
      "address": _addressController.text,
      "images":
          imageUrls.isNotEmpty
              ? imageUrls
              : [
                "https://s-housing.vn/wp-content/uploads/2022/09/thiet-ke-phong-tro-dep-7.jpg",
              ],
      "utilities": selectedUtilities,
      "type": selectedType ?? "",
      "category": selectedCategory ?? "",
      "postedBy": widget.userName,
      "phone": _phoneController.text,
    };

    try {
      final response = await http.post(
        Uri.parse("http://${Api.baseUrl}:8000/api/phongtro/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(postData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo phòng trọ thành công!")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi tạo phòng trọ: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    }
  }

  final types = [
    'Phòng trọ thường',
    'Phòng trọ có gác',
    'Phòng trọ cao cấp',
    'Chung cư mini',
    'Nhà nguyên căn',
    'Căn hộ dịch vụ',
    'Căn hộ chung cư',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[700],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Đăng tin"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: _inputDecoration("Loại phòng trọ *"),
                value: selectedType,
                items:
                    types
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value;
                  });
                },
                validator:
                    (value) =>
                        value == null ? 'Vui lòng chọn loại phòng' : null,
              ),
              const SizedBox(height: 16),
              const SectionHeader("THÔNG TIN CHI TIẾT"),
              const SizedBox(height: 8),
              _buildImageUrlInput(),
              const SizedBox(height: 16),
              _buildTextField(
                _titleController,
                "Tiêu đề tin đăng *",
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _priceController,
                "Giá thuê (VND) *",
                keyboardType: TextInputType.number,
                validator: _numberValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _areaController,
                "Diện tích (m²) *",
                keyboardType: TextInputType.number,
                validator: _numberValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _addressController,
                "Địa chỉ *",
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _descriptionController,
                "Mô tả chi tiết *",
                maxLines: 5,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 16),
              const SectionHeader("TIỆN ÍCH"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    availableUtilities.map((utility) {
                      return FilterChip(
                        label: Text(utility),
                        selected: selectedUtilities.contains(utility),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!selectedUtilities.contains(utility)) {
                                selectedUtilities.add(utility);
                              }
                            } else {
                              selectedUtilities.remove(utility);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              const SectionHeader("THÔNG TIN NGUỒN BÁN"),
              const SizedBox(height: 8),
              _buildTextField(
                _phoneController,
                "Số điện thoại *",
                keyboardType: TextInputType.phone,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Xem trước chưa được hỗ trợ"),
                            ),
                          );
                        }
                      },
                      child: const Text("Xem trước"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text("Đăng tin"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildImageUrlInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dán link hình ảnh (mỗi link trên một dòng, nhấn Enter để thêm link mới, tối đa 6 link)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _imageUrlsController,
            decoration: _inputDecoration('Link hình ảnh'),
            maxLines: 6,
            minLines: 3, // Đảm bảo hiển thị ít nhất 3 dòng
            keyboardType: TextInputType.multiline, // Hỗ trợ đa dòng
            textInputAction: TextInputAction.newline, // Phím Enter tạo dòng mới
            validator: _validateImageUrls,
            onChanged: (value) => _updateImageUrls(),
          ),
          const SizedBox(height: 8),
          Text('Đã nhập ${imageUrls.length}/6 link hình'),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'Không được bỏ trống' : null;

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Không được bỏ trống';
    return double.tryParse(value) == null ? 'Phải là số hợp lệ' : null;
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
