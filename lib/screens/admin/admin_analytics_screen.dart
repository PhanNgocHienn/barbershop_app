// ================ admin_analytics_screen.dart ================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Thêm các hằng số màu để dễ quản lý
const Color _primaryColor = Color(0xFF00796B); // Teal[700]
const Color _scaffoldBgColor = Color(0xFFF5F5F5); // Colors.grey[100]

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      // Fetch bookings data
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();

      final bookings = bookingsSnapshot.docs;

      // Calculate total bookings
      final totalBookings = bookings.length;

      // Calculate revenue (only from paid and completed bookings)
      double totalRevenue = 0;
      final revenueBookings = bookings.where((doc) {
        final status = doc.data()['status'];
        return status == 'paid' ||
            status == 'completed' ||
            status == 'reviewed';
      });
      for (var doc in revenueBookings) {
        final price = doc.data()['servicePrice'];
        if (price is num) {
          totalRevenue += price.toDouble();
        }
      }

      // Bookings by status
      final statusCounts = <String, int>{};
      for (var doc in bookings) {
        final status = doc.data()['status'] as String? ?? 'unknown';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      // Bookings over time (last 30 days)
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final bookingsOverTime = <DateTime, int>{};
      for (var doc in bookings) {
        final timestamp = doc.data()['startTime'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          if (date.isAfter(thirtyDaysAgo)) {
            final day = DateTime(date.year, date.month, date.day);
            bookingsOverTime[day] = (bookingsOverTime[day] ?? 0) + 1;
          }
        }
      }

      // Barber performance
      final barberCounts = <String, int>{};
      for (var doc in bookings) {
        final barberId = doc.data()['barberId'] as String?;
        if (barberId != null) {
          barberCounts[barberId] = (barberCounts[barberId] ?? 0) + 1;
        }
      }

      // Fetch barber names
      final barberNames = <String, String>{};
      for (var barberId in barberCounts.keys) {
        final barberDoc = await FirebaseFirestore.instance
            .collection('barbers')
            .doc(barberId)
            .get();
        if (barberDoc.exists) {
          barberNames[barberId] = barberDoc.data()?['name'] ?? 'Unknown';
        }
      }

      setState(() {
        _analyticsData = {
          'totalBookings': totalBookings,
          'totalRevenue': totalRevenue,
          'statusCounts': statusCounts,
          'bookingsOverTime': bookingsOverTime,
          'barberCounts': barberCounts,
          'barberNames': barberNames,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Bookings',
                    _analyticsData['totalBookings']?.toString() ?? '0',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Revenue',
                    '${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(_analyticsData['totalRevenue'] ?? 0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bookings by Status Chart
            _buildChartCard('Bookings by Status', _buildStatusPieChart()),
            const SizedBox(height: 24),

            // Bookings Over Time Chart
            _buildChartCard(
              'Bookings Over Last 30 Days',
              _buildBookingsOverTimeChart(),
            ),
            const SizedBox(height: 24),

            // Barber Performance Chart
            _buildChartCard(
              'Barber Performance',
              _buildBarberPerformanceChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart() {
    final statusCounts =
        _analyticsData['statusCounts'] as Map<String, int>? ?? {};
    if (statusCounts.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];
    int colorIndex = 0;

    statusCounts.forEach((status, count) {
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$status\n$count',
          color: colors[colorIndex % colors.length],
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return PieChart(
      PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40),
    );
  }

  Widget _buildBookingsOverTimeChart() {
    final bookingsOverTime =
        _analyticsData['bookingsOverTime'] as Map<DateTime, int>? ?? {};
    if (bookingsOverTime.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sortedDates = bookingsOverTime.keys.toList()..sort();
    final spots = <FlSpot>[];

    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), bookingsOverTime[sortedDates[i]]!.toDouble()),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedDates.length) {
                  final date = sortedDates[value.toInt()];
                  return Text(DateFormat('MM/dd').format(date));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _primaryColor,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberPerformanceChart() {
    final barberCounts =
        _analyticsData['barberCounts'] as Map<String, int>? ?? {};
    final barberNames =
        _analyticsData['barberNames'] as Map<String, String>? ?? {};
    if (barberCounts.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sortedBarbers = barberCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < sortedBarbers.length && i < 10; i++) {
      final entry = sortedBarbers[i];
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              color: _primaryColor,
              width: 16,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedBarbers.length &&
                    value.toInt() < 10) {
                  final barberId = sortedBarbers[value.toInt()].key;
                  final name = barberNames[barberId] ?? 'Unknown';
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      name.length > 8 ? '${name.substring(0, 8)}...' : name,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}
