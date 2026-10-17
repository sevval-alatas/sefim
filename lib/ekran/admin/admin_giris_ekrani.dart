// import 'dart:convert';
// import 'dart:io';
//
// import 'package:flutter/material.dart';
//
// import 'package:sefim/servis/auth_servisi.dart';
//
// class AdminGirisEkrani extends StatefulWidget {
//   final void Function(BuildContext context) onAuthenticated;
//
//   const AdminGirisEkrani({super.key, required this.onAuthenticated});
//
//   @override
//   State<AdminGirisEkrani> createState() => _AdminGirisEkraniState();
// }
//
// class _AdminGirisEkraniState extends State<AdminGirisEkrani> {
//   final AuthServisi _servis = AuthServisi();
//   final _formKey = GlobalKey<FormState>();
//   final _adminPassCtrl = TextEditingController();
//   bool _kayitModu = false;
//   bool _gonderiliyor = false;
//
//   @override
//   void initState() {
//     super.initState();
//     // Oturum açık mıysa direkt admin paneline yönlendir
//     if (AuthServisi.oturumAcik == 'admin') {
//       widget.onAuthenticated(context);
//     }
//   }
//
//   @override
//   void dispose() {
//     _adminPassCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _gonder() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _gonderiliyor = true);
//
//     try {
//       await _servis.adminLogin(password: _adminPassCtrl.text);
//       widget.onAuthenticated(context);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Hatalı şifre! Lütfen tekrar deneyin.")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1B2430),
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF1F497D),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: const Icon(
//                     Icons.admin_panel,
//                     color: Colors.white,
//                     size: 50,
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   'SEFIM\nAdmin Paneli',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 const Text(
//                   'İnşaat Yönetim Sistemi',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.white.withOpacity(0.6),
//                   ),
//                 ),
//                 const SizedBox(height: 48),
//
//                 Card(
//                   elevation: 8,
//                   color: const Color(0xFF1F497D),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24),
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.only(bottom: 8),
//                             child: Text(
//                               "Yönetici Şifresi",
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                           TextFormField(
//                             controller: _adminPassCtrl,
//                             obscureText: true,
//                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
//                             decoration: InputDecoration(
//                               hintText: "Yönetici şifrenizi girin",
//                               hintStyle: const TextStyle(color: Colors.white.withOpacity(0.5)),
//                               prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
//                               suffixIcon: IconButton(
//                                 icon: const Icon(Icons.visibility_off, color: Colors.white),
//                                 onPressed: () {
//                                   setState(() {
//                                     _adminPassCtrl.obscureText = false;
//                                   });
//                                 },
//                               ),
//                               filled: true,
//                               fillColor: Colors.white.withOpacity(0.1),
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                                 borderSide: BorderSide.none,
//                               ),
//                               enabledBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                                 borderSide: BorderSide.none,
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                                 borderSide: BorderSide(color: const Color(0xFF1F497D), width: 2),
//                               ),
//                             ),
//                             validator: (val) {
//                               if (val?.isEmpty ?? true) {
//                                 return 'Şifre boş olamaz';
//                               }
//                               if (val!.length < 6) {
//                                 return 'En az 6 karakter olmalı';
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 24),
//
//                           FilledButton(
//                             onPressed: _gonder,
//                             style: FilledButton.styleFrom(
//                               backgroundColor: const Color(0xFF1F497D),
//                               minimumSize: const Size.fromHeight(54),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                             ),
//                             child: _gonderiliyor
//                               ? const SizedBox(
//                                   width: 24,
//                                   height: 24,
//                                   child: CircularProgressIndicator(strokeWidth: 3),
//                                 )
//                               : const Text(
//                                   "Giriş Yap",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                           ),
//                           const SizedBox(height: 16),
//                           TextButton(
//                             onPressed: () {
//                               // Normal girişe yönlendir
//                               widget.onAuthenticated(context);
//                             },
//                             child: const Text(
//                               "Normal Giriş",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 32),
//                 const Text(
//                   "Giriş yapmak için yönetici şifrenizi giriniz",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.4),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }