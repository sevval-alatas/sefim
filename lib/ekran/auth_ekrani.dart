import 'package:flutter/material.dart';

import 'package:sefim/servis/auth_servisi.dart';

class AuthEkrani extends StatefulWidget {
  const AuthEkrani({required this.onAuthenticated, super.key});

  final void Function(BuildContext context) onAuthenticated;

  @override
  State<AuthEkrani> createState() => _AuthEkraniState();
}

class _AuthEkraniState extends State<AuthEkrani> {
  final AuthServisi _servis = AuthServisi();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _kayitModu = false;
  bool _sifreGosteriliyor = false;
  bool _gonderiliyor = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _gonderiliyor = true);
    try {
      if (_kayitModu) {
        await _servis.signup(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          username: _usernameCtrl.text,
          name: _nameCtrl.text,
        );
      } else {
        await _servis.login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      widget.onAuthenticated(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('İşlem başarısız: $error')));
    } finally {
      if (mounted) setState(() => _gonderiliyor = false);
    }
  }

  void _modDegistir() {
    setState(() {
      _kayitModu = !_kayitModu;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _logo(renkler),
                    const SizedBox(height: 28),
                    Text(
                      _kayitModu ? 'Hesap oluştur' : 'Tekrar hoş geldiniz',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _kayitModu
                          ? 'Sefim’i kullanmaya başlamak için bilgilerinizi girin.'
                          : 'Devam etmek için hesabınıza giriş yapın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 28),
                    if (_kayitModu) ...[
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Ad soyad',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _usernameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Kullanıcı adı',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return email.contains('@')
                            ? null
                            : 'Geçerli bir e-posta girin.';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_sifreGosteriliyor,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _gonder(),
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _sifreGosteriliyor = !_sifreGosteriliyor,
                          ),
                          icon: Icon(
                            _sifreGosteriliyor
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          tooltip: _sifreGosteriliyor
                              ? 'Şifreyi gizle'
                              : 'Şifreyi göster',
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) >= 8
                          ? null
                          : 'Şifre en az 8 karakter olmalı.',
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _gonderiliyor ? null : _gonder,
                      child: _gonderiliyor
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_kayitModu ? 'Kayıt ol' : 'Giriş yap'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _gonderiliyor ? null : _modDegistir,
                      child: Text(
                        _kayitModu
                            ? 'Zaten hesabınız var mı? Giriş yapın'
                            : 'Hesabınız yok mu? Kayıt olun',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo(ColorScheme renkler) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: renkler.primary.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset('assets/sefim_logo.jpeg', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sefim',
          style: TextStyle(
            color: renkler.primary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
