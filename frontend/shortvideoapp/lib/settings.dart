import 'package:flutter/material.dart';
import 'package:shortvideoapp/settings_pages/account_settings.dart';
import 'package:shortvideoapp/settings_pages/notifications.dart';
import 'package:shortvideoapp/settings_pages/screen_settings.dart';

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

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_left, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),

            // Account Section
            _buildSection("Account", [
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: "Account Settings",
                onTap: () => _navigateToPage(context, AccountSettingsPage()),
              ),
              _buildSettingItem(
                context,
                icon: Icons.security,
                title: "Privacy & Security",
                onTap: () => _navigateToPage(context, "Privacy & Security"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.notifications,
                title: "Notifications",
                onTap: () => _navigateToPage(context, NotificationsPage()),
              ),
            ]),

            SizedBox(height: 30),

            // Content Section
            _buildSection("Content", [
              _buildSettingItem(
                context,
                icon: Icons.video_library,
                title: "Content Preferences",
                onTap: () => _navigateToPage(context, "Content Preferences"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.language,
                title: "Language",
                onTap: () => _navigateToPage(context, "Language"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.dark_mode,
                title: "Screen",
                onTap: () => _navigateToPage(context, ScreenSettingsPage()),
              ),
            ]),

            SizedBox(height: 30),

            // Access Section
            _buildSection("Access", [
              _buildSettingItem(
                context,
                icon: Icons.accessibility,
                title: "Accessibility",
                onTap: () => _navigateToPage(context, "Accessibility"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.block,
                title: "Blocked Users",
                onTap: () => _navigateToPage(context, "Blocked Users"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.report,
                title: "Report Problem",
                onTap: () => _navigateToPage(context, "Report Problem"),
              ),
              _buildSettingItem(
                context,
                icon: Icons.logout,
                title: "Logout",
                onTap: () => _navigateToPage(context, "Logout"),
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
          margin: EdgeInsets.symmetric(horizontal: 16.0),
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
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
        transitionDuration: Duration(milliseconds: 300),
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
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
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
}
