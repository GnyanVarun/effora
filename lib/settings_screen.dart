import 'dart:math';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String? _username;
  String? _email;
  String? _profileImageUrl;
  bool _darkMode = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadDarkMode();
    _loadAppVersion();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('user_preferences')
            .select('username, profile_image_url')
            .eq('user_id', user.id)
            .maybeSingle();

        setState(() {
          _email = user.email;
          _username = response?['username'] ?? '';
          _profileImageUrl = response?['profile_image_url'];
        });
      }
    } catch (e) {
      debugPrint("Error loading user info: $e");
    }
  }

  Future<void> _loadDarkMode() async {
    final box = await Hive.openBox('preferences');
    setState(() {
      _darkMode = box.get('darkMode', defaultValue: false);
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final box = await Hive.openBox('preferences');
    await box.put('darkMode', value);
    setState(() {
      _darkMode = value;
    });
  }

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              final userId = supabase.auth.currentUser?.id;
              if (newUsername.isNotEmpty && userId != null) {
                await supabase
                    .from('user_preferences')
                    .update({'username': newUsername})
                    .eq('user_id', userId);
                setState(() {
                  _username = newUsername;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _setRandomAvatar() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final userId = user.id;
    final seed = 'effora_${Random().nextInt(999999)}';
    final newAvatarUrl = 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed';

    try {
      await supabase
          .from('user_preferences')
          .update({'profile_image_url': newAvatarUrl})
          .eq('user_id', userId);

      setState(() {
        _profileImageUrl = newAvatarUrl;
      });
    } catch (e) {
      debugPrint("Failed to set random avatar: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set random avatar: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  String get fallbackAvatarUrl {
    final seed = (_email ?? _username ?? 'effora_user').replaceAll(' ', '');
    return 'https://api.dicebear.com/7.x/adventurer/png?seed=$seed';
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _profileImageUrl != null
        ? NetworkImage(_profileImageUrl!)
        : NetworkImage(fallbackAvatarUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _setRandomAvatar,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: avatarImage,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _setRandomAvatar,
              icon: const Icon(Icons.refresh),
              label: const Text("Random Avatar"),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Username'),
                  subtitle: Text(_username ?? '—'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _editUsername,
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(_email ?? '—'),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: _darkMode,
                  onChanged: _toggleDarkMode,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Change Password"),
                  onTap: () {
                    Navigator.pushNamed(context, '/reset-password');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                const Text(
                  "Effora",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Empower your hustle, own your success.",
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text("v$_appVersion", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
