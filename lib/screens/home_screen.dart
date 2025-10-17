// lib/screens/home_screen.dart

import 'package:barbershop_app/models/barber_model.dart';
import 'package:barbershop_app/models/service_model.dart';
import 'package:barbershop_app/screens/barber_details_screen.dart';
import 'package:barbershop_app/screens/booking_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      // SafeArea để nội dung không bị che khuất bởi tai thỏ hay thanh trạng thái
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Phần Tiêu đề ---
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'TTH BarberShop xin chào!',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Hãy chọn một dịch vụ và đặt lịch ngay.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // --- Phần Thợ cắt tóc hàng đầu ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Thợ cắt tóc hàng đầu',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('barbers').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const BarberListSkeleton(); // Hiệu ứng chờ tải
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Chưa có thợ nào.'));
                    }
                    final barberDocs = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: barberDocs.length,
                      itemBuilder: (context, index) {
                        final barber = Barber.fromFirestore(barberDocs[index]);
                        return BarberCard(barber: barber);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // --- Phần Dịch vụ ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Dịch vụ của chúng tôi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('services').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ServiceListSkeleton(); // Hiệu ứng chờ tải
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('Chưa có dịch vụ nào.'));
                    }
                    final serviceDocs = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: serviceDocs.length,
                      itemBuilder: (context, index) {
                        final service = Service.fromFirestore(
                          serviceDocs[index],
                        );
                        return ServiceTile(service: service);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24), // Thêm khoảng trống ở cuối
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widget hiển thị một thợ cắt tóc ---
class BarberCard extends StatelessWidget {
  final Barber barber;
  const BarberCard({super.key, required this.barber});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => BarberDetailsScreen(barber: barber),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Hero(
              tag: barber.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: barber.imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              barber.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              barber.specialty,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Widget hiển thị một dịch vụ ---
class ServiceTile extends StatelessWidget {
  final Service service;
  const ServiceTile({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          service.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${service.duration} phút'),
        trailing: Text(
          '${service.price.toStringAsFixed(0)} VNĐ',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BookingScreen(service: service),
            ),
          );
        },
      ),
    );
  }
}

// --- Widget hiệu ứng chờ tải cho danh sách thợ ---
class BarberListSkeleton extends StatelessWidget {
  const BarberListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 16),
          child: Column(
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 10, width: 80, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widget hiệu ứng chờ tải cho danh sách dịch vụ ---
class ServiceListSkeleton extends StatelessWidget {
  const ServiceListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Container(height: 15, width: 150, color: Colors.white),
            subtitle: Container(height: 10, width: 80, color: Colors.white),
            trailing: Container(height: 15, width: 100, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
