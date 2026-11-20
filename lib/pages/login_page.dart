import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'device_demo_page.dart';
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
  String _selectedRole = 'seeker'; // 'seeker' | 'owner' | 'admin'
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Default isi form sebagai Pencari Kos
    _emailC.text = 'pencari@kosfinder.com';
    _passC.text = 'seeker123';
  }

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

  /// Mengganti Role di sekitar email (Pencari Kos, Pemilik Kos, Admin)
  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'admin') {
        _emailC.text = 'admin@contoh.com';
        _passC.text = 'admin123';
      } else if (role == 'owner') {
        _emailC.text = 'owner@contoh.com';
        _passC.text = 'owner123';
      } else {
        _emailC.text = 'pencari@kosfinder.com';
        _passC.text = 'seeker123';
      }
    });
  }

  /// Login dengan validasi kredensial
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
                  Icon(Icons.home_work_rounded, size: 70, color: Theme.of(context).colorScheme.primary),
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

                  // 1. TEMPAT PILIH / GANTI ROLE DI SEKITAR EMAIL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_outlined, size: 18, color: Colors.indigo.shade800),
                            const SizedBox(width: 8),
                            Text(
                              'Pilih Peran / Role Akun:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // 1. Pencari Kos
                            Expanded(
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.person_search,
                                  size: 16,
                                  color: _selectedRole == 'seeker' ? Colors.white : Colors.indigo,
                                ),
                                label: const Text('Pencari Kos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: _selectedRole == 'seeker',
                                selectedColor: Colors.indigo,
                                labelStyle: TextStyle(
                                  color: _selectedRole == 'seeker' ? Colors.white : Colors.black87,
                                ),
                                onSelected: (val) {
                                  if (val) _selectRole('seeker');
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 2. Pemilik Kos
                            Expanded(
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.home_work,
                                  size: 16,
                                  color: _selectedRole == 'owner' ? Colors.white : Colors.teal.shade700,
                                ),
                                label: const Text('Pemilik Kos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: _selectedRole == 'owner',
                                selectedColor: Colors.teal.shade700,
                                labelStyle: TextStyle(
                                  color: _selectedRole == 'owner' ? Colors.white : Colors.black87,
                                ),
                                onSelected: (val) {
                                  if (val) _selectRole('owner');
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 3. Admin
                            Expanded(
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.admin_panel_settings,
                                  size: 16,
                                  color: _selectedRole == 'admin' ? Colors.white : Colors.deepPurple,
                                ),
                                label: const Text('Admin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                selected: _selectedRole == 'admin',
                                selectedColor: Colors.deepPurple.shade700,
                                labelStyle: TextStyle(
                                  color: _selectedRole == 'admin' ? Colors.white : Colors.black87,
                                ),
                                onSelected: (val) {
                                  if (val) _selectRole('admin');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. INPUT EMAIL
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

                  // 3. INPUT PASSWORD
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

                  // 4. TOMBOL LOGIN UTAMA
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

                  // 5. LINK KE REGISTER
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text('Belum punya akun? Register di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),

                  // 6. AKSES LANGSUNG WORKSHEET 10
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DeviceDemoPage()),
                    ),
                    icon: const Icon(Icons.perm_device_information, color: Colors.teal),
                    label: const Text(
                      'Buka Worksheet 10: Device Demo (Kamera & GPS)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.teal.shade400, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
