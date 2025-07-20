import 'package:flutter/material.dart';
import 'package:shortvideoapp/screens/main/home.dart';
import 'services/localization_service.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main/create.dart';
import 'screens/main/profile.dart';
import 'screens/main/search.dart';
import 'screens/main/messages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await LocalizationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) {
        return MaterialApp(
          title: 'Short Video App',
          theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
          home: const AuthChecker(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storageService.getToken();
    final user = await _storageService.getUser();

    setState(() {
      _isLoggedIn = token != null && user != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? const MainApp() : const LoginScreen();
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // GlobalKey to access HomePageState
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  // Declare screens list but initialize in initState
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize screens list here where _homePageKey is available
    _screens = [
      HomePage(key: _homePageKey),
      const SearchScreen(),
      const CreateVideoPage(),
      const MessagesScreen(),
      const ProfilePage(userId: -1, username: '', isPublicUser: false)
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      return; // Don't do anything if already on that page
    }

    // If switching away from home tab (index 0), pause the video
    if (_currentIndex == 0 && index != 0) {
      _homePageKey.currentState?.pauseCurrentVideo();
    }

    // If switching to home tab (index 0), resume the video
    if (index == 0 && _currentIndex != 0) {
      _homePageKey.currentState?.resumeCurrentVideo();
    }

    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
        onPageChanged: (index) {
          // Only update state when page actually changes
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 95,
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                _buildNavItem(
                  icon:
                      _currentIndex == 1 ? Icons.search : Icons.search_outlined,
                  label: 'Search',
                  isActive: _currentIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                _buildCreateButton(),
                _buildNavItem(
                  icon: _currentIndex == 3
                      ? Icons.chat_bubble
                      : Icons.chat_bubble_outlined,
                  label: 'Messages',
                  isActive: _currentIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
                _buildNavItem(
                  icon:
                      _currentIndex == 4 ? Icons.person : Icons.person_outlined,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => _onItemTapped(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFF4444).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isActive ? const Color(0xFFFF4444) : Colors.grey[400],
                  size: isActive ? 26 : 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive ? const Color(0xFFFF4444) : Colors.grey[400],
                  fontSize: isActive ? 11 : 9,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          gradient: _currentIndex == 2
              ? LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.red[500]!, Colors.red[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _currentIndex == 2 ? 1.1 : 1.0,
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
