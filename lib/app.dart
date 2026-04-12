import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/view/auth_screen.dart';
import 'features/bilty_new/view/new_bilty_screen.dart';
import 'features/challan/view/new_challan_screen.dart';
import 'features/dashboard/view/dashboard_screen.dart';
import 'features/master_data/view/master_data_screen.dart';
import 'features/profile/view/profile_screen.dart';
import 'features/splash/view/splash_screen.dart';
import 'features/trip_mgmt/view/trip_management_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/bilty_provider.dart';
import 'providers/challan_provider.dart';
import 'providers/master_data_provider.dart';
import 'providers/trip_management_provider.dart';

class FreightFlowApp extends StatelessWidget {
  const FreightFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MasterDataProvider()),
        ChangeNotifierProvider(create: (_) => BiltyProvider()),
        ChangeNotifierProvider(create: (_) => ChallanProvider()),
        ChangeNotifierProvider(create: (_) => TripManagementProvider()),
      ],
      child: MaterialApp(
        title: 'FreightFlow',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        // ── Splash screen is the entry point ─────────────────────────────
        home: SplashScreen(nextScreen: const _AuthGate()),
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  static Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/bilty-new':  page = const NewBiltyScreen();    break;
      case '/challan':    page = const NewChallanScreen();  break;
      case '/trip-new':   page = const NewTripScreen();     break;
      case '/master':     page = const MasterDataScreen();  break;
      case '/profile':    page = const ProfileScreen();     break;
      default:            page = const _AuthGate();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

// ── Auth guard ────────────────────────────────────────────────────────────────

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) return const _AppShell();
    return const AuthScreen();
  }
}

// ── App shell with 5-tab bottom nav ──────────────────────────────────────────

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to safely call providers after the widget tree is built.
    // This prevents "called during build" errors while avoiding multiple calls.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      context.read<MasterDataProvider>().enableCloud(userId);
      context.read<BiltyProvider>().enableCloud(userId);
      context.read<ChallanProvider>().enableCloud(userId);
      context.read<TripManagementProvider>().enableCloud(userId);
    });
  }

  static const _screens = [
    DashboardScreen(),
    TripManagementScreen(),
    NewBiltyScreen(),
    MasterDataScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.route_outlined),
      activeIcon: Icon(Icons.route_rounded),
      label: 'Trips',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      activeIcon: Icon(Icons.receipt_long_rounded),
      label: 'New Bilty',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.manage_accounts_outlined),
      activeIcon: Icon(Icons.manage_accounts_rounded),
      label: 'Master',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE8EAF0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          items: _items,
        ),
      ),
    );
  }
}