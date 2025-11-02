// lib/screens/home_screen.dart
import 'package:barbershop_app/models/barber_model.dart';
import 'package:barbershop_app/models/service_model.dart';
import 'package:barbershop_app/screens/barber_details_screen.dart';
import 'package:barbershop_app/screens/booking_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:barbershop_app/screens/service_menu_screen.dart';
import '../admin/admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'BESPOKE BARBERING',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final isAdmin =
                  (snapshot.data?.data()
                      as Map<String, dynamic>?)?['isAdmin'] ==
                  true;
              if (!isAdmin) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                ),
                tooltip: 'Admin',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Banner
            _buildHeroBanner(),

            const SizedBox(height: 24),

            // Services Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildServicesSection(context, firestore),
            ),

            const SizedBox(height: 40),

            // Barbers Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: _buildBarbersSection(context, firestore, width),
            ),

            const SizedBox(height: 40),

            // Locations Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildLocationsSection(context),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Hero Banner
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black87, Colors.grey.shade800],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.network(
                'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.content_cut, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'ĐẶT LỊCH HÔM NAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trải nghiệm dịch vụ chuyên nghiệp',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Services Section
  Widget _buildServicesSection(
    BuildContext context,
    FirebaseFirestore firestore,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'DỊCH VỤ CỦA CHÚNG TÔI',
          'Chọn dịch vụ phù hợp với bạn',
          Icons.design_services,
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CompactServicesSkeleton();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('Chưa có dịch vụ nào');
            }
            final serviceDocs = snapshot.data!.docs;
            return Column(
              children: serviceDocs.map((doc) {
                final service = Service.fromFirestore(doc);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CompactServiceCard(service: service),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Barbers Section
  Widget _buildBarbersSection(
    BuildContext context,
    FirebaseFirestore firestore,
    double width,
  ) {
    final crossAxisCount = width < 600
        ? 2
        : width < 900
        ? 3
        : 4;

    return Column(
      children: [
        _buildSectionHeader(
          'THỢ CẮT TÓC HÀNG ĐẦU',
          'Đội ngũ chuyên nghiệp và tận tâm',
          Icons.people,
        ),
        const SizedBox(height: 20),
        StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('barbers').limit(10).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return BarbersGridSkeleton(crossAxisCount: crossAxisCount);
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState('Chưa có thợ nào');
            }
            final barberDocs = snapshot.data!.docs;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
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

  // Locations Section
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
      children: [
        _buildSectionHeader(
          'ĐỊA ĐIỂM CỦA CHÚNG TÔI',
          'Tìm cửa hàng gần bạn nhất',
          Icons.location_on,
        ),
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

  // Section Header
  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Empty State
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Location Card
  Widget _buildLocationCard(
    String title,
    String address,
    String description,
    String imageUrl,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.stars, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
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

// Compact Service Card
class CompactServiceCard extends StatelessWidget {
  final Service service;
  const CompactServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingScreen(service: service),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.content_cut,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${service.duration} phút',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${service.price.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ĐẶT NGAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
}

// Barber Grid Card
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  barber.imageUrl?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: barber.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      barber.name ?? 'Chưa có tên',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        barber.specialty ?? 'Chuyên gia',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton Loaders
class CompactServicesSkeleton extends StatelessWidget {
  const CompactServicesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class BarbersGridSkeleton extends StatelessWidget {
  final int crossAxisCount;
  const BarbersGridSkeleton({super.key, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
