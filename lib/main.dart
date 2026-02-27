import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/app_state.dart';
import 'models/listing_model.dart';
import 'models/trade_model.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/profile_setup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/listings/listings_screen.dart';
import 'screens/listings/create_listing_screen.dart';
import 'screens/listings/listing_detail_screen.dart';
import 'screens/trades/trades_screen.dart';
import 'screens/trades/trade_detail_screen.dart';
import 'screens/credit/wallet_screen.dart';
import 'screens/disputes/disputes_screen.dart';
import 'screens/quality/quality_check_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NanonMeshApp());
}

class NanonMeshApp extends StatelessWidget {
  const NanonMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'NanonMesh',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return _fadeRoute(const SplashScreen());
            case '/login':
              return _slideRoute(const LoginScreen());
            case '/otp':
              final phone = settings.arguments as String? ?? '';
              return _slideRoute(OtpScreen(phoneNumber: phone));
            case '/profile-setup':
              final phone = settings.arguments as String? ?? '';
              return _slideRoute(ProfileSetupScreen(phoneNumber: phone));
            case '/home':
              return _fadeRoute(const MainShell());
            case '/create-listing':
              return _slideRoute(const CreateListingScreen());
            case '/listing-detail':
              final listing = settings.arguments as ListingModel;
              return _slideRoute(ListingDetailScreen(listing: listing));
            case '/listings':
              return _slideRoute(const ListingsScreen());
            case '/trades':
              return _slideRoute(const TradesScreen());
            case '/trade-detail':
              final trade = settings.arguments as TradeModel;
              return _slideRoute(TradeDetailScreen(trade: trade));
            case '/wallet':
              return _slideRoute(const WalletScreen());
            case '/disputes':
              return _slideRoute(const DisputesScreen());
            case '/quality-check':
              return _slideRoute(const QualityCheckScreen());
            default:
              return _fadeRoute(const SplashScreen());
          }
        },
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Main app shell with bottom navigation
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    ListingsScreen(),
    // Center placeholder for FAB
    SizedBox(),
    TradesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        onPressed: () => Navigator.pushNamed(context, '/create-listing'),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 68,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black.withValues(alpha: 0.15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(0, Icons.home_rounded, 'Home'),
            _navItem(1, Icons.storefront_rounded, 'Market'),
            const SizedBox(width: 48), // Space for FAB
            _navItem(3, Icons.swap_calls_rounded, 'Trades'),
            _navItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
