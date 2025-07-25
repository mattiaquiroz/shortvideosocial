import 'package:flutter/material.dart';
import 'package:shortvideoapp/screens/settings/account_settings.dart';
import 'package:shortvideoapp/screens/settings/notifications.dart';
import 'package:shortvideoapp/screens/settings/screen_settings.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/screens/auth/login_screen.dart';
import 'package:shortvideoapp/screens/settings/language_selection_screen.dart';
import 'package:shortvideoapp/constants/strings.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.settings,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left,
              color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Account Section
            _buildSection(AppStrings.account, [
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: AppStrings.accountSettings,
                onTap: () =>
                    _navigateToPage(context, const AccountSettingsPage()),
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: AppStrings.privacySecurity,
                onTap: () => _navigateToPage(context, "Privacy & Security"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: AppStrings.notifications,
                onTap: () =>
                    _navigateToPage(context, const NotificationsPage()),
              ),
            ]),

            const SizedBox(height: 30),

            // Content Section
            _buildSection(AppStrings.content, [
              _buildSettingItem(
                context,
                icon: Icons.video_library,
                title: AppStrings.contentPreferences,
                onTap: () => _navigateToPage(context, "Content Preferences"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.language,
                title: AppStrings.language,
                onTap: () => _navigateToLanguageSelection(context),
              ),
              _buildSettingItem(
                context,
                icon: Icons.dark_mode,
                title: AppStrings.screen,
                onTap: () =>
                    _navigateToPage(context, const ScreenSettingsPage()),
              ),
            ]),

            const SizedBox(height: 30),

            // Access Section
            _buildSection(AppStrings.access, [
              _buildSettingItem(
                context,
                icon: Icons.accessibility,
                title: AppStrings.accessibility,
                onTap: () => _navigateToPage(context, "Accessibility"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.block,
                title: AppStrings.blockedUsers,
                onTap: () => _navigateToPage(context, "Blocked Users"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.report,
                title: AppStrings.reportProblem,
                onTap: () => _navigateToPage(context, "Report Problem"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.logout,
                title: _isLoggingOut ? AppStrings.loading : AppStrings.logout,
                onTap: _isLoggingOut ? () {} : () => _logout(),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, dynamic page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            page is Widget ? page : _buildPlaceholderPage(page as String),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderPage(String title) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_left,
              color: Colors.black,
              size: 30,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: Text(
          '$title Page',
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      ),
    );
  }

  void _navigateToLanguageSelection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
    );

    // If language was changed, rebuild the settings page
    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      await _apiService.logout();

      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoggingOut = false);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
