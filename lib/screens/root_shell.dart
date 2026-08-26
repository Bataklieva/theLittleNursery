import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'admin/admin_home_screen.dart';
import 'calendar/calendar_screen.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'locations/locations_screen.dart';
import 'profile/profile_screen.dart';

/// Bottom-navigation shell for the top-level parent-facing sections, plus
/// a sixth "Admin" tab that only appears for accounts with editing rights
/// (see AuthService.isAdmin).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _parentScreens = [
    HomeScreen(),
    CalendarScreen(),
    LibraryScreen(),
    LocationsScreen(),
    ProfileScreen(),
  ];

  static const _parentItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined),
      activeIcon: Icon(Icons.calendar_today),
      label: 'Calendar',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_outlined),
      activeIcon: Icon(Icons.menu_book),
      label: 'Library',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.place_outlined),
      activeIcon: Icon(Icons.place),
      label: 'Locations',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthService, bool>((auth) => auth.isAdmin);

    final screens = [
      ..._parentScreens,
      if (isAdmin) const AdminHomeScreen(),
    ];
    final items = [
      ..._parentItems,
      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
    ];

    // Losing admin rights (or signing into a non-admin account) shouldn't
    // leave the tab index pointing past the end of a now-shorter list.
    final safeIndex = _index < screens.length ? _index : 0;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }
}
