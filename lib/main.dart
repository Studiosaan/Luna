import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweph/sweph.dart';
import 'package:untitled/screens/home_screen.dart';
import 'package:untitled/screens/settings_screen.dart';
import 'package:untitled/screens/info_screen.dart';
import 'package:untitled/moon_phase_provider.dart';
import 'package:timezone/data/latest_all.dart'
    as tz; // latest.dart 대신 latest_all.dart 사용

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone 초기화
  tz.initializeTimeZones();

  try {
    await Sweph.init(
      epheAssets: [
        'assets/semo_18.se1',
        'assets/sepl_18.se1',
        // 'assets/sefstars.txt', // 필요 시 추가
      ],
    );
    print('Sweph initialization successful!');
  } catch (e) {
    print('Sweph initialization failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => MoonPhaseProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moon Phase App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    HomeScreen(),
    SettingsScreen(),
    InfoScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: '정보'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
