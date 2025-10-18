// lib/screens/service_menu_screen.dart
import 'package:flutter/material.dart';

class ServiceMenuScreen extends StatelessWidget {
  const ServiceMenuScreen({super.key});

  // --- Màu sắc từ ảnh ---
  final Color scaffoldBgColor = const Color(0xFF3a2e2c); // Màu nền texture tối
  final Color formBgColor = const Color(0xFFFAF3E6); // Màu nền beige của form
  final Color primaryColor = const Color(0xFFD4AF37); // Màu vàng gold/nâu sáng
  final Color titleColor = const Color(0xFF6B4F3B); // Màu chữ nâu đậm
  final Color textColor = const Color(0xFF6B4F3B); // Màu chữ trong menu
  final Color descColor = const Color(0xFF8C7B70); // Màu mô tả
  final Color dividerColor = const Color(0xFFE0D9CE); // Màu đường kẻ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: const Text(
          'Bảng Giá Dịch Vụ',
          style: TextStyle(color: Color(0xFFD4AF37)),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        // Nút quay lại (back button) sẽ tự động xuất hiện
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Giới hạn chiều rộng
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              decoration: BoxDecoration(
                color: formBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Header ---
                  _buildHeader(),
                  const SizedBox(height: 30),

                  // --- Combo Haircut ---
                  _buildMenuCategoryTitle('COMBO HAIRCUT'),
                  _buildMenuItem(
                    name: 'THE REGULAR',
                    duration: '(30 - 40 minutes)',
                    descEN: 'Hair cut - Hair style',
                    descVI: 'Cắt tóc - sấy tóc - tạo kiểu',
                    price: '150',
                  ),
                  _buildMenuItem(
                    name: 'THE SIGNATURE',
                    duration: '(60 minutes)',
                    descEN: 'Hair cut - Hair style - Shampoo - Cond',
                    descVI: 'Cắt tóc - gội thư giãn - xả tóc - sấy - tạo kiểu',
                    price: '200',
                    save: '50',
                  ),
                  _buildMenuItem(
                    name: 'THE ULTIMATE',
                    duration: '(90 minutes)',
                    descEN: 'The Signature & Hot Towel',
                    descVI: 'Gội Signature và Cạo khăn nóng truyền thống',
                    price: '300',
                    save: '50',
                  ),
                  _buildMenuItem(
                    name: 'HOT TOWEL',
                    duration: '(30 minutes)',
                    descEN: 'Refresihng Classic Hot Towel Shave',
                    descVI: 'Thư giãn với cạo râu khăn nóng truyền thống',
                    price: '100 - 150',
                  ),

                  const SizedBox(height: 30),

                  // --- Other Services ---
                  _buildMenuCategoryTitle('OTHER SERVICES'),
                  _buildMenuItem(
                    name: 'HEAD SHAVE',
                    descEN: 'Straight razor all over with after shave',
                    descVI: 'Cạo trọc với kem chuyên dụng và dưỡng kem',
                    price: '200',
                  ),
                  _buildMenuItem(
                    name: 'YOUNG 2S',
                    descEN: 'Children haircut (Under 7 years old)',
                    descVI: 'Cắt tóc cho trẻ em dưới 7 tuổi',
                    price: '100',
                  ),
                  _buildMenuItem(
                    name: 'SHAMPOO & COND',
                    descEN: 'Refreshing shampoo massage & condition',
                    descVI: 'Gội đầu thư giãn & xả tóc',
                    price: '100',
                  ),
                  _buildMenuItem(
                    name: 'HAIR STYLE',
                    descEN: 'Sấy & Tạo kiểu tóc với sản phẩm phù hợp',
                    descVI: 'Dành cho khách hàng cần làm tóc sự kiện',
                    price: '50',
                  ),
                  _buildMenuItem(
                    name: 'HOME BARBERING',
                    descEN: 'Cắt tóc tận nơi',
                    descVI: 'Barber chuyên môn cao phục vụ tận nơi.',
                    price: '400',
                  ),
                  _buildMenuItem(
                    name: 'STRAIGHTEN',
                    descEN: 'Hair straightening',
                    descVI: 'Ép thẳng tóc, ép phồng chân tóc, ép side part...',
                    price: '200 - 600',
                  ),
                  _buildMenuItem(
                    name: 'PERM - BASIC',
                    descEN: 'Basic Perm Hairstyle',
                    descVI: 'Uốn tạo kiểu, uốn lơi, uốn gợn, uốn phồng...',
                    price: '500 - 600',
                  ),
                  _buildMenuItem(
                    name: 'PERM - ADVANCE',
                    descEN: 'Permlock, Textured, Curly...',
                    descVI: 'Uốn tạo kiểu xu hướng',
                    price: '700 - 1600',
                  ),
                  _buildMenuItem(
                    name: 'COLORING',
                    descEN: 'Basic coloring hair',
                    descVI: 'Nhuộm màu phổ thông không tẩy tóc',
                    price: '500 - 600',
                  ),
                  _buildMenuItem(
                    name: 'COLORING & BLEACH',
                    descEN: 'Trending hair color with bleach',
                    descVI: 'Nhuộm xu hướng có tẩy tóc',
                    price: '700 - 1600',
                  ),

                  const SizedBox(height: 30),

                  // --- Bottom Buttons (ĐÃ SỬA LỖI OVERFLOW) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Sử dụng Flexible để các nút co giãn
                      Flexible(child: _buildOutlineButton('BOOK NOW')),
                      const SizedBox(width: 8), // Thêm khoảng cách giữa các nút
                      Flexible(child: _buildOutlineButton('HOME & WEDDINGS')),
                      const SizedBox(width: 8),
                      Flexible(child: _buildOutlineButton('TEST KIỂU TÓC')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'MENU',
          style: TextStyle(
            color: titleColor,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'HIGHFIVE BESPOKE BARBERING',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: titleColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String name,
    String? duration,
    required String descEN,
    required String descVI,
    required String price,
    String? save,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phần text (Tên, mô tả)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên + (save)
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name.toUpperCase(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (save != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '(save $save)',
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (duration != null)
                      Text(
                        duration,
                        style: TextStyle(color: descColor, fontSize: 13),
                      ),
                    Text(
                      descEN,
                      style: TextStyle(color: descColor, fontSize: 13),
                    ),
                    Text(
                      descVI,
                      style: TextStyle(color: descColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Phần giá
              Text(
                price,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: dividerColor, height: 1),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(String text) {
    return OutlinedButton(
      onPressed: () {}, // Nút tĩnh, không có chức năng
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: textColor.withOpacity(0.7), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        // Giảm padding ngang để các nút có thêm không gian
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
      child: Text(
        text,
        // Giảm kích thước font một chút nếu cần thiết
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        textAlign: TextAlign.center, // Để chữ tự xuống dòng nếu dài
      ),
    );
  }
}
