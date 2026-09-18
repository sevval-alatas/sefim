import 'package:flutter/material.dart';

/// Excel'e kaydedilecek tek bir alanı temsil eden, zorunlu ve boşsa
/// kullanıcıyı görsel olarak (kırmızı çerçeve + ikon) uyaran ortak metin
/// alanı. `readOnly` + `onTap` verildiğinde tarih/saat seçici gibi
/// dokunmatik seçicilerle birlikte kullanılabilir.
class IrsaliyeAlan extends StatefulWidget {
  const IrsaliyeAlan({
    super.key,
    required this.etiket,
    required this.controller,
    required this.ikon,
    this.zorunlu = false,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String etiket;
  final TextEditingController controller;
  final IconData ikon;
  final bool zorunlu;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  State<IrsaliyeAlan> createState() => _IrsaliyeAlanState();
}

class _IrsaliyeAlanState extends State<IrsaliyeAlan> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_degistiginde);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_degistiginde);
    super.dispose();
  }

  void _degistiginde() {
    if (mounted) setState(() {});
  }

  bool get _bos => widget.zorunlu && widget.controller.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final renkler = Theme.of(context).colorScheme;
    final uyariRengi = Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: widget.controller,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: widget.zorunlu ? '${widget.etiket} *' : widget.etiket,
          labelStyle: _bos ? TextStyle(color: uyariRengi) : null,
          prefixIcon: Icon(
            widget.ikon,
            size: 20,
            color: _bos ? uyariRengi : null,
          ),
          suffixIcon: widget.readOnly
              ? Icon(
                  Icons.arrow_drop_down,
                  color: renkler.primary.withValues(alpha: 0.6),
                )
              : (_bos
                  ? Icon(Icons.error_outline, size: 18, color: uyariRengi)
                  : null),
          isDense: true,
          enabledBorder: _bos
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: uyariRengi, width: 1.2),
                )
              : null,
        ),
      ),
    );
  }
}

/// Basınç dayanımı için hazır beton sınıfları. Listede olmayan bir değer
/// gerekiyorsa "Diğer (elle gir)" seçeneğiyle serbest metin girişine
/// geçilebilir.
const List<String> betonSiniflari = [
  'C16/20',
  'C20/25',
  'C25/30',
  'C30/37',
  'C35/45',
  'C40/50',
  'C45/55',
  'C50/60',
];

class DayanimAlani extends StatefulWidget {
  const DayanimAlani({
    super.key,
    required this.controller,
    this.zorunlu = false,
  });

  final TextEditingController controller;
  final bool zorunlu;

  @override
  State<DayanimAlani> createState() => _DayanimAlaniState();
}

class _DayanimAlaniState extends State<DayanimAlani> {
  static const String _digerDeger = 'Diğer (elle gir)';
  late bool _elleGiriliyor;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_degistiginde);
    final mevcut = widget.controller.text.trim();
    _elleGiriliyor = mevcut.isNotEmpty && !betonSiniflari.contains(mevcut);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_degistiginde);
    super.dispose();
  }

  void _degistiginde() {
    if (mounted) setState(() {});
  }

  bool get _bos => widget.zorunlu && widget.controller.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final uyariRengi = Colors.red.shade400;
    const etiket = 'Basınç Dayanımı';

    if (_elleGiriliyor) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: widget.zorunlu ? '$etiket *' : etiket,
            labelStyle: _bos ? TextStyle(color: uyariRengi) : null,
            prefixIcon: Icon(
              Icons.foundation_outlined,
              size: 20,
              color: _bos ? uyariRengi : null,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.list_alt_outlined, size: 20),
              tooltip: 'Listeden seç',
              onPressed: () {
                setState(() {
                  _elleGiriliyor = false;
                  if (!betonSiniflari.contains(widget.controller.text.trim())) {
                    widget.controller.clear();
                  }
                });
              },
            ),
            isDense: true,
          ),
        ),
      );
    }

    final mevcutDeger = betonSiniflari.contains(widget.controller.text.trim())
        ? widget.controller.text.trim()
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: mevcutDeger,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: widget.zorunlu ? '$etiket *' : etiket,
          labelStyle: _bos ? TextStyle(color: uyariRengi) : null,
          prefixIcon: Icon(
            Icons.foundation_outlined,
            size: 20,
            color: _bos ? uyariRengi : null,
          ),
          isDense: true,
        ),
        items: [
          ...betonSiniflari.map(
            (s) => DropdownMenuItem(value: s, child: Text(s)),
          ),
          const DropdownMenuItem(value: _digerDeger, child: Text(_digerDeger)),
        ],
        onChanged: (deger) {
          if (deger == null) return;
          if (deger == _digerDeger) {
            setState(() {
              _elleGiriliyor = true;
              widget.controller.clear();
            });
          } else {
            setState(() {
              widget.controller.text = deger;
            });
          }
        },
      ),
    );
  }
}
