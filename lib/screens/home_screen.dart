import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../moon_phase_provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class HomeScreen extends StatelessWidget {
  final TextEditingController _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final moonPhase = Provider.of<MoonPhaseProvider>(context);

    _dateController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(moonPhase.selectedDate);

    return Scaffold(
      appBar: AppBar(title: Text('달의 위상')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildMoonPhaseCard(moonPhase),
            _buildZodiacCard(moonPhase),
            _buildVoidOfCourseCard(moonPhase),
            _buildDateSelectorCard(context, moonPhase),
            if (moonPhase.errorMessage.isNotEmpty)
              Card(
                color: Colors.red[100],
                child: ListTile(
                  title: Text('오류'),
                  subtitle: Text(moonPhase.errorMessage),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhaseCard(MoonPhaseProvider moonPhase) {
    IconData getPhaseIcon(String phase) {
      switch (phase) {
        case 'new_moon':
          return Icons.brightness_1;
        case 'waxing_crescent':
          return Icons.brightness_2;
        case 'first_quarter':
          return Icons.brightness_3;
        case 'waxing_gibbous':
          return Icons.brightness_4;
        case 'full_moon':
          return Icons.brightness_5;
        case 'waning_gibbous':
          return Icons.brightness_6;
        case 'last_quarter':
          return Icons.brightness_7;
        case 'waning_crescent':
          return Icons.brightness_low;
        default:
          return Icons.help;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Moon Phase',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  getPhaseIcon(moonPhase.currentPhase),
                  size: 40,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text(moonPhase.currentPhase, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '다음 변경: ${moonPhase.nextPhaseTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZodiacCard(MoonPhaseProvider moonPhase) {
    IconData getZodiacIcon(String zodiac) {
      switch (zodiac) {
        case '양자리':
          return Icons.local_fire_department;
        case '황소자리':
          return Icons.local_florist;
        case '쌍둥이자리':
          return Icons.people;
        case '게자리':
          return Icons.local_dining;
        case '사자자리':
          return Icons.local_cafe;
        case '처녀자리':
          return Icons.local_hospital;
        case '천칭자리':
          return Icons.balance;
        case '전갈자리':
          return Icons.local_police;
        case '사수자리':
          return Icons.local_police;
        case '염소자리':
          return Icons.local_police;
        case '물병자리':
          return Icons.local_drink;
        case '물고기자리':
          return Icons.local_police;
        default:
          return Icons.help;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Moon in',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  getZodiacIcon(moonPhase.currentZodiac),
                  size: 40,
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                Text(moonPhase.currentZodiac, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '종료 시점: ${moonPhase.nextZodiacTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoidOfCourseCard(MoonPhaseProvider moonPhase) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_queue, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Void of Course',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              moonPhase.isVoidOfCourse ? '보이드 상태' : '보이드 아님',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              moonPhase.isVoidOfCourse
                  ? '종료 시점: ${moonPhase.voidOfCourseTime}'
                  : '다음 시작: ${moonPhase.voidOfCourseTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectorCard(
    BuildContext context,
    MoonPhaseProvider moonPhase,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.blue),
                  onPressed: () {
                    moonPhase.setDate(
                      moonPhase.selectedDate.subtract(Duration(days: 1)),
                    );
                    _dateController.text = DateFormat(
                      'yyyy-MM-dd HH:mm',
                    ).format(moonPhase.selectedDate);
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      labelText: '날짜 입력 (yyyy-mm-dd HH:mm)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.datetime,
                    onSubmitted:
                        (value) => _handleDateInput(context, value, moonPhase),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                  onPressed: () {
                    moonPhase.setDate(
                      moonPhase.selectedDate.add(Duration(days: 1)),
                    );
                    _dateController.text = DateFormat(
                      'yyyy-MM-dd HH:mm',
                    ).format(moonPhase.selectedDate);
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '선택된 날짜: ${DateFormat('yyyy-MM-dd HH:mm').format(moonPhase.selectedDate)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateInput(
    BuildContext context,
    String input,
    MoonPhaseProvider moonPhase,
  ) {
    try {
      final parts = input.split(' ');
      if (parts.length != 2) {
        throw FormatException('날짜 형식이 잘못되었습니다. yyyy-mm-dd HH:mm 형식을 사용하세요.');
      }
      final dateParts = parts[0].split('-');
      final timeParts = parts[1].split(':');
      if (dateParts.length != 3 || timeParts.length != 2) {
        throw FormatException('잘못된 형식입니다.');
      }

      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1].padLeft(2, '0'));
      final day = int.parse(dateParts[2].padLeft(2, '0'));
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final newDate = DateTime.utc(year, month, day, hour, minute);
      if (newDate.year != year ||
          newDate.month != month ||
          newDate.day != day ||
          newDate.hour != hour ||
          newDate.minute != minute) {
        throw FormatException('유효하지 않은 날짜 또는 시간입니다.');
      }

      moonPhase.setDate(newDate);
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(newDate);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }
}
