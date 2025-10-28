// lib/screens/booking_screen.dart

import 'package:barbershop_app/models/barber_model.dart';
import 'package:barbershop_app/models/service_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:barbershop_app/screens/barber_details_screen.dart';
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
  // --- Màu sắc từ ảnh ---
  final Color scaffoldBgColor = const Color(0xFF3a2e2c); // Màu nền texture tối
  final Color formBgColor = const Color(0xFFFAF3E6); // Màu nền beige của form
  final Color primaryColor = const Color(0xFFD4AF37); // Màu vàng gold/nâu sáng
  final Color textColor = const Color(0xFF6B4F3B); // Màu chữ nâu đậm

  // --- Trạng thái cho Form ---
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestsController = TextEditingController(text: '1');
  String? _selectedLocation = 'cholon'; // Giá trị mặc định

  // --- Trạng thái cho Lịch & Giờ (Từ code cũ) ---
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
    '18:00',
    '19:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    if (widget.preselectedBarber != null) {
      _selectedBarberId = widget.preselectedBarber!.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guestsController.dispose();
    super.dispose();
  }

  // --- Hàm xử lý ---

  Future<void> _confirmBooking() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) {
      EasyLoading.showError('Vui lòng điền đủ thông tin bắt buộc.');
      return;
    }

    // 2. Validate Lịch (Từ code cũ)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        _selectedDay == null ||
        _selectedTimeSlot == null ||
        _selectedBarberId == null ||
        _selectedLocation == null) {
      EasyLoading.showError('Vui lòng chọn đầy đủ thông tin lịch hẹn.');
      return;
    }

    EasyLoading.show(status: 'Đang xử lý...');

    // 3. Chuẩn bị dữ liệu
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
      // 4. Chống trùng slot bằng transaction + ID định danh
      final slotKey =
          '${_selectedBarberId}_${DateFormat('yyyyMMdd_HHmm').format(appointmentDateTime)}';
      final docRef =
          FirebaseFirestore.instance.collection('appointments').doc(slotKey);

      await FirebaseFirestore.instance.runTransaction((txn) async {
        final snap = await txn.get(docRef);
        if (snap.exists) {
          final existingStatus = snap.data()?['status'] as String?;
          // Nếu slot đã tồn tại và chưa bị hủy, chặn đặt trùng
          if (existingStatus != null && existingStatus != 'cancelled') {
            throw Exception('Khung giờ này đã có người đặt.');
          }
        }

        txn.set(docRef, {
          // --- Dữ liệu từ Form mới ---
          'userName': _nameController.text.trim(),
          'userPhone': _phoneController.text.trim(),
          'guests': int.tryParse(_guestsController.text.trim()) ?? 1,
          'location': _selectedLocation,

          // --- Dữ liệu từ logic cũ ---
          'userId': user.uid,
          'serviceName': widget.service.name,
          'servicePrice': widget.service.price,
          'barberId': _selectedBarberId,
          'appointmentTime': Timestamp.fromDate(appointmentDateTime),
          'status': 'scheduled',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      EasyLoading.showSuccess('Đặt lịch thành công!');
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      EasyLoading.showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      EasyLoading.dismiss();
    }
  }

  // --- Widgets ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar trong suốt, không bóng, chỉ định màu icon và tiêu đề
      appBar: AppBar(
        backgroundColor: Colors.transparent, // chỉ khai báo 1 lần
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'BOOKING',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ), // Giới hạn chiều rộng
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: formBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Header ---
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // --- Form Fields (Mới) ---
                      _buildSectionTitle('Thông tin cá nhân'),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Tên - Name *',
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Vui lòng nhập tên'
                            : null,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Số điện thoại - Phone *',
                        keyboardType: TextInputType.phone,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Vui lòng nhập SĐT'
                            : null,
                      ),
                      _buildTextField(
                        controller: _guestsController,
                        label: 'Số khách',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),

                      // --- Chọn Địa điểm (Mới) ---
                      _buildSectionTitle('Booking Location *'),
                      _buildLocationRadios(),
                      const SizedBox(height: 20),

                      // --- Chọn Thợ (Từ code cũ - đã re-style) ---
                      if (widget.preselectedBarber == null) ...[
                        _buildSectionTitle('Chọn thợ cắt tóc *'),
                        _buildBarberSelector(),
                        const SizedBox(height: 20),
                      ],

                      // --- Chọn Ngày (Từ code cũ - đã re-style) ---
                      _buildSectionTitle('Chọn ngày *'),
                      _buildCalendar(),
                      const SizedBox(height: 20),

                      // --- Chọn Giờ (Từ code cũ - đã re-style) ---
                      _buildSectionTitle('Chọn khung giờ *'),
                      _buildTimeSlots(),
                      const SizedBox(height: 30),

                      // --- Nút Submit ---
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      _buildFooterText(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'BOOKING',
          style: TextStyle(
            color: textColor,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'MỖI BARBER CÓ MỘT LƯỢT FREE CẮT TÓC - BẠN CÓ LÀ NGƯỜI MAY MẮN?\n'
          'MỞI NGÀY TỪ THỨ HAI - THỨ SÁU',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOutlineButton('ƯU ĐÃI'),
            const SizedBox(width: 15),
            _buildOutlineButton('TEST KIỂU TÓC'),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Enter text',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationRadios() {
    return Column(
      children: [
        RadioListTile<String>(
          title: Text(
            'Highfive Cholon - Quận 5',
            style: TextStyle(color: textColor),
          ),
          value: 'cholon',
          groupValue: _selectedLocation,
          onChanged: (value) => setState(() => _selectedLocation = value),
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: Text(
            'Highfive Saigon - Quận 3',
            style: TextStyle(color: textColor),
          ),
          value: 'saigon',
          groupValue: _selectedLocation,
          onChanged: (value) => setState(() => _selectedLocation = value),
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: Text(
            'Home Barbering - Cắt tóc tận nơi',
            style: TextStyle(color: textColor),
          ),
          value: 'home',
          groupValue: _selectedLocation,
          onChanged: (value) => setState(() => _selectedLocation = value),
          activeColor: primaryColor,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildBarberSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('barbers').snapshots(),
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
                  _selectedTimeSlot = null; // Reset giờ khi đổi thợ
                });
              },
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : textColor,
              ),
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.shade400,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 60)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedTimeSlot = null; // Reset giờ khi đổi ngày
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: textColor),
          weekendTextStyle: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
          rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    if (_selectedDay == null || _selectedBarberId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Vui lòng chọn ngày và thợ cắt tóc để xem giờ trống.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ),
      );
    }

    // Logic StreamBuilder (từ code cũ)
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
                  ? null // Vô hiệu hóa nếu đã đặt
                  : (selected) {
                      setState(
                        () => _selectedTimeSlot = selected ? time : null,
                      );
                    },
              backgroundColor: isBooked ? Colors.grey.shade400 : Colors.white,
              selectedColor: primaryColor,
              labelStyle: TextStyle(
                color: isBooked
                    ? Colors.white
                    : (isSelected ? Colors.white : textColor),
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isBooked
                      ? Colors.grey.shade400
                      : (isSelected ? primaryColor : Colors.grey.shade400),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOutlineButton(String text) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: primaryColor, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _confirmBooking,
      child: const Text(
        'SUBMIT',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildFooterText() {
    return Column(
      children: [
        Text(
          'Trong trường hợp đặt lịch gấp trực tiếp, quý khách vui lòng ghé Page Highfive Barbershop hoặc gọi hotline 0908.421.461',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          'Highfive xin cảm ơn quý khách đã đặt dịch vụ. Chúc quý khách một ngày vui vẻ. Thank you for your booking. Have a nice day!',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
