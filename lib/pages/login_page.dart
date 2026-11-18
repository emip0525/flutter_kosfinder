import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  /// Login reguler dengan validasi kredensial (akun belum terdaftar DITOLAK)
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await AuthService.instance.login(
        email: _emailC.text.trim(),
        password: _passC.text,
      );

      if (!mounted) return;
      _showMessage('Login berhasil! Selamat datang di KosFinder.', isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal login: Periksa kembali email dan password Anda.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Masuk Cepat langsung dengan Role Pilihan (Pencari Kos / Pemilik Kos / Admin)
  Future<void> _loginDirectRole(String role, String label) async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.loginAsRole(role);
      if (!mounted) return;
      _showMessage('Berhasil masuk sebagai $label!', isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal masuk: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillAndLogin(String email, String pass) {
    _emailC.text = email;
    _passC.text = pass;
    _login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login KosFinder', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.home_work_rounded, size: 68, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  const Text(
                    'KosFinder',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const Text(
                    'Temukan kos impian atau pasarkan properti Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // 1. KOTAK PILIHAN MASUK SEBAGAI ROLE (Pencari Kos, Pemilik Kos, Admin)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, size: 18, color: Colors.indigo),
                            SizedBox(width: 6),
                            Text(
                              'Pilih Masuk Cepat Berdasarkan Role:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Tombol Pencari Kos
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _loading ? null : () => _loginDirectRole('seeker', 'Pencari Kos'),
                                icon: const Icon(Icons.person_search, size: 18),
                                label: const Text('Pencari Kos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tombol Pemilik Kos
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _loading ? null : () => _loginDirectRole('owner', 'Pemilik Kos'),
                                icon: const Icon(Icons.home_work, size: 18),
                                label: const Text('Pemilik Kos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tombol Admin
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _loading ? null : () => _loginDirectRole('admin', 'Admin KosFinder'),
                          icon: const Icon(Icons.admin_panel_settings, size: 18),
                          label: const Text('Masuk Sebagai Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('ATAU LOGIN MANUAL', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. FORM LOGIN DENGAN VALIDASI KETAT
                  TextFormField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'nama@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passC,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text('Belum punya akun? Register di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Pintasan Isi Form Akun Terdaftar:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 14, color: Colors.indigo),
                        label: const Text('Seeker Form', style: TextStyle(fontSize: 11)),
                        onPressed: () => _fillAndLogin('pencari@kosfinder.com', 'seeker123'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.home_work, size: 14, color: Colors.teal),
                        label: const Text('Owner A Form', style: TextStyle(fontSize: 11)),
                        onPressed: () => _fillAndLogin('owner@contoh.com', 'owner123'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.domain, size: 14, color: Colors.orange),
                        label: const Text('Owner B Form', style: TextStyle(fontSize: 11)),
                        onPressed: () => _fillAndLogin('owner2@contoh.com', 'owner123'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.admin_panel_settings, size: 14, color: Colors.deepPurple),
                        label: const Text('Admin Form', style: TextStyle(fontSize: 11)),
                        onPressed: () => _fillAndLogin('admin@contoh.com', 'admin123'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
