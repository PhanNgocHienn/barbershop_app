// lib/screens/booking_screen.dart

import 'package:barbershop_app/models/barber_model.dart';
import 'package:barbershop_app/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  final Service service;
  final Barber? preselectedBarber;

  const BookingScreen({
    super.key,
    required this.service,
    this.preselectedBarber,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedTimeSlot;
  String? _selectedBarberId;

  final List<String> _workingHours = [
    '09:00',
    '10:00',
    '11:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    if (widget.preselectedBarber != null) {
      _selectedBarberId = widget.preselectedBarber!.id;
    }
  }

  void _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _selectedDay == null ||
        _selectedTimeSlot == null ||
        _selectedBarberId == null) {
      EasyLoading.showError('Vui lòng chọn đầy đủ thông tin.');
      return;
    }
    EasyLoading.show(status: 'Đang xử lý...');
    final timeParts = _selectedTimeSlot!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final appointmentDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      hour,
      minute,
    );
    try {
      await FirebaseFirestore.instance.collection('appointments').add({
        'userId': user.uid,
        'serviceName': widget.service.name,
        'servicePrice': widget.service.price,
        'barberId': _selectedBarberId,
        'appointmentTime': Timestamp.fromDate(appointmentDateTime),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
      EasyLoading.showSuccess('Đặt lịch thành công!');
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      EasyLoading.showError('Đã xảy ra lỗi: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  Widget _buildTimeSlots() {
    if (_selectedDay == null || _selectedBarberId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Vui lòng chọn ngày và thợ cắt tóc để xem giờ trống.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final startOfDay = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('barberId', isEqualTo: _selectedBarberId)
          .where(
            'appointmentTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('appointmentTime', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Lỗi khi tải dữ liệu giờ.'));
        }
        final bookedSlots = snapshot.data?.docs.map((doc) {
          final timestamp = doc['appointmentTime'] as Timestamp;
          return DateFormat('HH:mm').format(timestamp.toDate());
        }).toSet();
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _workingHours.map((time) {
            final isBooked = bookedSlots?.contains(time) ?? false;
            final isSelected = _selectedTimeSlot == time;
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              onSelected: isBooked
                  ? null
                  : (selected) {
                      setState(
                        () => _selectedTimeSlot = selected ? time : null,
                      );
                    },
              backgroundColor: isBooked ? Colors.grey.shade400 : null,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isBooked
                    ? Colors.white
                    : (isSelected ? Colors.white : Colors.black),
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đặt lịch: ${widget.service.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 60)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedTimeSlot = null;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            if (widget.preselectedBarber == null) ...[
              const Text(
                'Chọn thợ cắt tóc',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('barbers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final barberDocs = snapshot.data!.docs;
                  return Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: barberDocs.map((doc) {
                      final barber = Barber.fromFirestore(doc);
                      final isSelected = _selectedBarberId == barber.id;
                      return ChoiceChip(
                        avatar: CircleAvatar(
                          backgroundImage: NetworkImage(barber.imageUrl),
                        ),
                        label: Text(barber.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedBarberId = selected ? barber.id : null;
                            _selectedTimeSlot = null;
                          });
                        },
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
            ],
            const Text(
              'Chọn khung giờ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimeSlots(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              (_selectedDay != null &&
                  _selectedTimeSlot != null &&
                  _selectedBarberId != null)
              ? _confirmBooking
              : null,
          child: const Text(
            'Xác nhận đặt lịch',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
