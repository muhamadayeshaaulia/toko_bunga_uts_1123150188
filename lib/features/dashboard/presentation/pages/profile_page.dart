import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../admin/kelola-produk/pages/admin_product_page.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/notification_service.dart';
import 'transaction_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isEmoneyConnected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBiometricStatus();
    _loadEmoneyStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEmoneyStatus();
    }
  }

  Future<void> _loadEmoneyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEmoneyConnected = prefs.getBool('is_emoney_connected') ?? false;
    });
  }

  Future<void> _loadBiometricStatus() async {
    final available = await BiometricService.isAvailable();
    final enabled = await BiometricService.isEnabled();
    setState(() {
      _isBiometricAvailable = available;
      _isBiometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Minta autentikasi dulu sebelum mengaktifkan
      final authenticated = await BiometricService.authenticate();
      if (!authenticated) return; // Batal jika gagal
    }
    await BiometricService.setEnabled(value);
    setState(() => _isBiometricEnabled = value);

    await NotificationService.showNotification(
      title: 'Keamanan Biometrik',
      body: value ? 'Sidik jari berhasil diaktifkan.' : 'Sidik jari berhasil dinonaktifkan.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userFirebase = auth.firebaseUser;
    final userBackend = auth.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Profil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: userFirebase?.photoURL != null
                        ? NetworkImage(userFirebase!.photoURL!)
                        : null,
                    child: userFirebase?.photoURL == null
                        ? const Icon(Icons.person, size: 50, color: Colors.blueAccent)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userBackend?['name'] ?? userFirebase?.displayName ?? 'Nama Pengguna',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (userFirebase?.emailVerified ?? false) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    userFirebase?.email ?? 'email@domain.com',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: auth.isAdmin ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      auth.isAdmin ? 'ADMIN' : 'USER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: auth.isAdmin ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Menu Pilihan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (auth.isAdmin) ...[
                    _buildProfileMenu(
                      icon: Icons.inventory_2_outlined,
                      title: 'Kelola Produk',
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminProductPage()),
                        );
                      },
                    ),
                    const Divider(),
                  ],

                  _buildProfileMenu(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan Akun',
                    onTap: () {},
                  ),
                  _buildProfileMenu(
                    icon: Icons.history_rounded,
                    title: 'Riwayat Transaksi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TransactionHistoryPage()),
                      );
                    },
                  ),

                  // ─── Toggle Biometrik ───
                  if (_isBiometricAvailable) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: _isBiometricEnabled
                            ? Colors.blue.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isBiometricEnabled
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: SwitchListTile(
                        secondary: Icon(
                          Icons.fingerprint,
                          color: _isBiometricEnabled ? Colors.blueAccent : Colors.grey,
                          size: 28,
                        ),
                        title: const Text(
                          'Sidik Jari untuk Login',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _isBiometricEnabled ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isBiometricEnabled ? Colors.blueAccent : Colors.grey,
                          ),
                        ),
                        value: _isBiometricEnabled,
                        onChanged: _toggleBiometric,
                        activeColor: Colors.blueAccent,
                      ),
                    ),
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.fingerprint, color: Colors.grey, size: 28),
                      title: const Text(
                        'Sidik Jari untuk Login',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      subtitle: const Text(
                        'Perangkat tidak mendukung biometrik',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],

                  _buildProfileMenu(
                    icon: Icons.shield_outlined,
                    title: 'Keamanan',
                    onTap: () {},
                  ),
                  const Divider(),

                  // ─── Hubungkan / Putuskan E-Money Wallet ───
                  if (_isEmoneyConnected)
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet_rounded, color: Colors.blue),
                      title: const Text('E-Money Mamah Saya', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Terhubung', style: TextStyle(fontSize: 12, color: Colors.green)),
                      trailing: TextButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Putuskan Hubungan'),
                              content: const Text('Anda yakin ingin memutuskan hubungan dengan E-Money Wallet?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Putuskan', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final emoneyUri = Uri.parse('emoneyapp://disconnect');
                            try {
                              await launchUrl(emoneyUri, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('E-Money Wallet belum terinstall atau gagal dibuka.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('Putuskan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    _buildProfileMenu(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Hubungkan E-Money Wallet',
                      color: Colors.green,
                      onTap: () async {
                        final emoneyUri = Uri.parse('emoneyapp://connect');
                        try {
                          await launchUrl(emoneyUri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('E-Money Wallet belum terinstall atau gagal dibuka.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  const Divider(height: 40),

                  // Tombol Logout
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, AppRouter.login);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: const Text('Keluar dari Akun',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.blueAccent,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}