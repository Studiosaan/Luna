import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('정보')),
      body: Center(
        child: Text('앱 정보: Swiss Ephemeris를 사용하여 달의 위상을 계산합니다.'),
      ),
    );
  }
}