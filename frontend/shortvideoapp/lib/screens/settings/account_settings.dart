import 'package:flutter/material.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/models/user_model.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  User? user;
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    final api = ApiService();
    // Try to fetch the latest user data from the backend
    final result = await api.refreshCurrentUser();
    if (result['success'] == true && result['user'] != null) {
      setState(() {
        user = result['user'];
        isLoading = false;
      });
    } else {
      // Fallback to local storage if backend call fails
      final currentUser = await api.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          error = 'User not found';
          isLoading = false;
        });
        return;
      }
      setState(() {
        user = currentUser;
        isLoading = false;
      });
    }
  }

  Future<void> _updateUserField(
      {String? username, String? email, String? fullName}) async {
    if (user == null) return;
    setState(() {
      isSaving = true;
      error = null;
    });
    final api = ApiService();
    final result = await api.updateUserProfile(
      userId: user!.id,
      username: username,
      email: email,
      fullName: fullName,
    );
    if (result['success'] == true) {
      setState(() {
        if (username != null) user = user!.copyWith(username: username);
        if (email != null) user = user!.copyWith(email: email);
        if (fullName != null) user = user!.copyWith(fullName: fullName);
        isSaving = false;
      });
    } else {
      setState(() {
        error = result['message'] ?? 'Failed to update';
        isSaving = false;
      });
    }
  }

  Future<void> _updatePrivateAccount(bool value) async {
    if (user == null) return;
    setState(() {
      isSaving = true;
      error = null;
    });
    final api = ApiService();
    final result = await api.updateUserProfile(
      userId: user!.id,
      isPrivateAccount: value,
    );
    if (result['success'] == true) {
      setState(() {
        user = user!.copyWith(isPrivateAccount: value);
        isSaving = false;
      });
    } else {
      setState(() {
        error = result['message'] ?? 'Failed to update';
        isSaving = false;
      });
    }
  }

  Future<void> _changePasswordDialog() async {
    String currentPassword = '';
    String newPassword = '';
    String? errorMsg;
    bool isSubmitting = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(AppStrings.changePassword),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: AppStrings.currentPassword),
                    onChanged: (v) => currentPassword = v,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: AppStrings.newPassword),
                    onChanged: (v) => newPassword = v,
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setState(() => isSubmitting = true);
                          final api = ApiService();
                          final result = await api.changePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword,
                          );
                          if (result['success'] == true) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              errorMsg = result['message'] ??
                                  'Failed to change password';
                              isSubmitting = false;
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppStrings.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.accountSettings)),
        body: Center(child: Text(error!)),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppStrings.accountSettings,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

            // Profile Information Section
            _buildSection(AppStrings.profileInformation, [
              _buildSettingItem(
                icon: Icons.person,
                title: AppStrings.fullName,
                subtitle:
                    (user!.fullName == null || user!.fullName!.trim().isEmpty)
                        ? AppStrings.addFullName
                        : user!.fullName!,
                onTap: () => _showEditDialog(
                    AppStrings.fullName, user!.fullName ?? '', (value) async {
                  await _updateUserField(fullName: value);
                }),
              ),
              _buildSettingItem(
                icon: Icons.email,
                title: AppStrings.email,
                subtitle: user!.email,
                onTap: () => _showEditDialog(AppStrings.email, user!.email,
                    (value) async {
                  await _updateUserField(email: value);
                }),
              ),
              _buildSettingItem(
                icon: Icons.lock,
                title: AppStrings.changePassword ?? 'Change Password',
                subtitle: AppStrings.changePasswordDesc ??
                    'Change your account password',
                onTap: _changePasswordDialog,
              ),
            ]),

            const SizedBox(height: 30),

            // Privacy Section
            _buildSection(AppStrings.privacy, [
              _buildSwitchItem(
                icon: Icons.lock,
                title: AppStrings.privateAccount,
                subtitle: AppStrings.privateAccountDesc,
                value: user!.isPrivateAccount,
                onChanged:
                    isSaving ? null : (value) => _updatePrivateAccount(value),
              ),
            ]),

            const SizedBox(height: 30),

            // Account Actions Section
            _buildSection(AppStrings.accountActions, [
              _buildSettingItem(
                icon: Icons.delete_forever,
                title: AppStrings.deleteAccount,
                subtitle: AppStrings.deleteAccountDesc,
                onTap: () => _showDeleteAccountDialog(context),
                isDestructive: true,
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

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
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

  void _showEditDialog(
    String title,
    String currentValue,
    Function(String) onSave,
  ) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${AppStrings.edit} $title"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteAccount),
        content: Text(AppStrings.deleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showInfoDialog(
                AppStrings.accountDeleted,
                AppStrings.accountDeletedDesc,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
