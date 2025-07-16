import 'package:flutter/material.dart';
import 'package:shortvideoapp/constants/strings.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool smsNotifications = false;
  bool likesNotifications = true;
  bool commentsNotifications = true;
  bool followersNotifications = true;
  bool mentionsNotifications = true;
  bool directMessages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.notifications,
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

            // General Section
            _buildSection(AppStrings.general, [
              _buildSwitchItem(
                icon: Icons.notifications,
                title: AppStrings.pushNotifications,
                subtitle: AppStrings.pushNotificationsDesc,
                value: pushNotifications,
                onChanged: (value) {
                  setState(() => pushNotifications = value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.email,
                title: AppStrings.emailNotifications,
                subtitle: AppStrings.emailNotificationsDesc,
                value: emailNotifications,
                onChanged: (value) {
                  setState(() => emailNotifications = value);
                },
              ),
            ]),

            SizedBox(height: 30),

            // Activity Section
            _buildSection(AppStrings.activity, [
              _buildSwitchItem(
                icon: Icons.favorite,
                title: AppStrings.likesNotification,
                subtitle: AppStrings.likesNotificationDesc,
                value: likesNotifications,
                onChanged: (value) {
                  setState(() => likesNotifications = value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.comment,
                title: AppStrings.commentsNotification,
                subtitle: AppStrings.commentsNotificationDesc,
                value: commentsNotifications,
                onChanged: (value) {
                  setState(() => commentsNotifications = value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.person_add,
                title: AppStrings.newFollowers,
                subtitle: AppStrings.newFollowersDesc,
                value: followersNotifications,
                onChanged: (value) {
                  setState(() => followersNotifications = value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.alternate_email,
                title: AppStrings.mentions,
                subtitle: AppStrings.mentionsDesc,
                value: mentionsNotifications,
                onChanged: (value) {
                  setState(() => mentionsNotifications = value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.message,
                title: AppStrings.directMessages,
                subtitle: AppStrings.directMessagesDesc,
                value: directMessages,
                onChanged: (value) {
                  setState(() => directMessages = value);
                },
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

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.blue),
        ],
      ),
    );
  }
}
