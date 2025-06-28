import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('설정')),
      body: Center(
        child: Text('설정 화면: 시간대, 테마 등을 설정하세요.'),
      ),
    );
  }
}