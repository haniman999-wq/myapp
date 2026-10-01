import 'package:flutter/material.dart';

import '../services/customer_database.dart';
import '../theme.dart';
import 'calendar_screen.dart';
import 'contact_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final _database = CustomerDatabase.instance;
  int _selectedIndex = 0;

  /// '연락' 탭 배지에 보여줄 환자 수 (재방문 미연락 + 복약 확인 필요).
  int _contactCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _database.changes.addListener(_reloadCount);
    _reloadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _database.changes.removeListener(_reloadCount);
    super.dispose();
  }

  /// 앱을 다시 열면 날짜가 바뀌었을 수 있으니 전체를 새로 계산합니다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _database.notifyChanged();
  }

  Future<void> _reloadCount() async {
    final overviews = await _database.getOverviews();
    final count = overviews
        .where(
          (o) => (o.needsContact && !o.contactedSinceDue) || o.needsHerbCheck,
        )
        .length;
    if (mounted) setState(() => _contactCount = count);
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const CalendarScreen(),
      const HomeScreen(),
      const ContactScreen(),
      const SearchScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryGreenDark,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '달력',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: '환자'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _contactCount > 0,
              label: Text('$_contactCount'),
              child: const Icon(Icons.notifications),
            ),
            label: '연락',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}
