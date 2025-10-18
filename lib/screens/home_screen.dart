// lib/screens/home_screen.dart
import 'package:barbershop_app/models/barber_model.dart';
import 'package:barbershop_app/models/service_model.dart';
import 'package:barbershop_app/screens/barber_details_screen.dart';
import 'package:barbershop_app/screens/booking_screen.dart'; // Form ĐỘNG
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
// 1. THÊM IMPORT CHO FILE MENU TĨNH
import 'package:barbershop_app/screens/service_menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'BESPOKE BARBERING',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Services Section ---
            _buildServicesSection(context, firestore),

            const SizedBox(height: 40),

            // --- Barbers Section ---
            _buildBarbersSection(context, firestore, width),

            const SizedBox(height: 40),

            // --- Locations Section ---
            _buildLocationsSection(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Services Section (ĐÃ CẬP NHẬT VỚI NÚT MỚI) ---
  Widget _buildServicesSection(
    BuildContext context,
    FirebaseFirestore firestore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Để nút bấm co dãn
      children: [
        const Text(
          'DỊCH VỤ CỦA CHÚNG TÔI',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 80, height: 3, color: const Color(0xFFD4AF37)),
        const SizedBox(height: 20),

        // 2. THÊM NÚT ĐIỀU HƯỚNG TẠI ĐÂY
        OutlinedButton.icon(
          icon: const Icon(Icons.menu_book, color: Color(0xFFD4AF37), size: 20),
          label: const Text(
            'XEM CHI TIẾT BẢNG GIÁ DỊCH VỤ',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            // Điều hướng tới BẢNG GIÁ TĨNH
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ServiceMenuScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 20), // Thêm khoảng cách
        // --- KẾT THÚC THÊM MỚI ---

        // StreamBuilder giữ nguyên (để điều hướng qua form ĐỘNG)
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CompactServicesSkeleton();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có dịch vụ nào.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            final serviceDocs = snapshot.data!.docs;
            return Column(
              children: serviceDocs.map((doc) {
                final service = Service.fromFirestore(doc);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CompactServiceCard(service: service),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // --- Barbers Section (Đã sửa lỗi treo máy) ---
  Widget _buildBarbersSection(
    BuildContext context,
    FirebaseFirestore firestore,
    double width,
  ) {
    final crossAxisCount = width < 600 ? 2 : 3; // mobile: 2, tablet: 3

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THỢ CẮT TÓC HÀNG ĐẦU',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 80, height: 3, color: const Color(0xFFD4AF37)),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          // Sửa lỗi treo máy: Giới hạn tải 10 thợ
          stream: firestore.collection('barbers').limit(10).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const BarbersGridSkeleton();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có thợ nào.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            final barberDocs = snapshot.data!.docs;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: barberDocs.length,
              itemBuilder: (context, index) {
                final barber = Barber.fromFirestore(barberDocs[index]);
                return BarberGridCard(barber: barber);
              },
            );
          },
        ),
      ],
    );
  }

  // --- Locations Section (Giữ nguyên) ---
  Widget _buildLocationsSection(BuildContext context) {
    final locations = [
      {
        'title': 'HIGHFIVE SAIGON',
        'address': '561 Điện Biên Phủ, Bàn Cờ',
        'desc': 'Mang hơi thở của một Sài Gòn hào hoa thanh lịch.',
        'image':
            'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
      },
      {
        'title': 'HIGHFIVE CHOLON',
        'address': '175 An Dương Vương, An Đông',
        'desc': 'Highfive Chợ Lớn - nơi văn hóa kết hợp cùng văn hóa cắt tóc.',
        'image':
            'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=800',
      },
      {
        'title': 'HOME SERVICE',
        'address': 'Cắt tóc tận nơi',
        'desc': 'Barber chuyên môn cao phục vụ tận nơi.',
        'image':
            'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=800',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ĐỊA ĐIỂM CỦA CHÚNG TÔI',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 80, height: 3, color: const Color(0xFFD4AF37)),
        const SizedBox(height: 20),
        Column(
          children: locations.map((loc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildLocationCard(
                loc['title']!,
                loc['address']!,
                loc['desc']!,
                loc['image']!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    String title,
    String address,
    String description,
    String imageUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Compact Service Card (Giữ nguyên điều hướng ĐỘNG) ---
class CompactServiceCard extends StatelessWidget {
  final Service service;
  const CompactServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Điều hướng đến form ĐỘNG với dịch vụ cụ thể
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingScreen(service: service),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${service.duration} phút',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${service.price.toStringAsFixed(0)}đ',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Barber Card (Đã sửa lỗi bo góc) ---
class BarberGridCard extends StatelessWidget {
  final Barber barber;
  const BarberGridCard({super.key, required this.barber});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => BarberDetailsScreen(barber: barber),
          ),
        );
      },
      child: Container(
        // Sửa lỗi bo góc: Thêm clipBehavior
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              // Bỏ ClipRRect thừa
              child: CachedNetworkImage(
                imageUrl: barber.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[800]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    barber.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    barber.specialty,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Skeleton Loaders ---
class CompactServicesSkeleton extends StatelessWidget {
  const CompactServicesSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class BarbersGridSkeleton extends StatelessWidget {
  const BarbersGridSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
