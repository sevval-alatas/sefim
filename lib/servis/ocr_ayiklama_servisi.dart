import 'irsaliye_verisi.dart';

/// OCR motorunun okuduğu ham metin bloğundan irsaliyenin 7 temel alanını
/// ayıklar. Masaüstü Python aracındaki `metinden_verileri_ayikla`
/// fonksiyonunun aynı regex mantığıyla Dart'a taşınmış halidir.
class OcrAyiklamaServisi {
  static IrsaliyeVerisi metindenVerileriAyikla(String tumMetin) {
    final veri = IrsaliyeVerisi(siparisMiktari: '-');

    final satirlar = tumMetin
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // -------------------------------------------------------------
    // 1. İRSALİYE NO (Örn: E-Irsaliye No: BCE2026000003093)
    // -------------------------------------------------------------
    RegExpMatch? mNo =
        RegExp(r'\b(BCE\s*\d{10,14})\b', caseSensitive: false).firstMatch(tumMetin);
    mNo ??= RegExp(
      r'(?:E[- ]?Irsaliye|İrsaliye)[^\n\d]*([A-Z0-9]{13,17})',
      caseSensitive: false,
    ).firstMatch(tumMetin);
    mNo ??= RegExp(
      r'\b((?:H\d{2}|GIB|[A-Z]{3})\s*\d{10,14})\b',
      caseSensitive: false,
    ).firstMatch(tumMetin);

    if (mNo != null) {
      veri.irsaliyeNo =
          (mNo.group(1) ?? '').replaceAll(RegExp(r'\s+'), '').toUpperCase();
    }

    // -------------------------------------------------------------
    // 2. İRSALİYE TARİHİ VE ZAMANI (Örn: 27 03.2026 12.55,18)
    // -------------------------------------------------------------
    final mTs = RegExp(
      r'(\b\d{1,2}[\s.,/-]\s*\d{1,2}[\s.,/-]\s*(?:20)?\d{2,4}\b)\s*([0-2]?\d[:.,][0-5]\d(?:[:.,][0-5]\d)?)',
    ).firstMatch(tumMetin);

    if (mTs != null) {
      final hamT = mTs.group(1)!.trim().split(RegExp(r'[\s.,/-]+'));
      if (hamT.length >= 3 && !hamT[0].contains('30')) {
        final yil = hamT[2].length == 4 ? hamT[2] : '20${hamT[2]}';
        veri.tarih = '${_ikiHane(hamT[0])}-${_ikiHane(hamT[1])}-$yil';
        final hamSaat = mTs.group(2)!.replaceAll(RegExp(r'[,.]'), ':');
        veri.zaman = hamSaat.length > 8 ? hamSaat.substring(0, 8) : hamSaat;
      }
    }

    // Tarih tek yakalanmışsa:
    if (veri.tarih.isEmpty) {
      final tumTarihler = RegExp(
        r'\b\d{1,2}[\s.,/-]\s*\d{1,2}[\s.,/-]\s*(?:20)?\d{2,4}\b',
      ).allMatches(tumMetin).map((m) => m.group(0)!).toList();

      for (final t in tumTarihler) {
        final temizT = t.replaceAll(RegExp(r'\s+'), '');
        final ilkIki = temizT.length >= 2 ? temizT.substring(0, 2) : temizT;
        if (temizT != '30.09.2024' && !ilkIki.contains('30')) {
          final parts = temizT.split(RegExp(r'[.,/-]'));
          if (parts.length >= 3) {
            final yil = parts[2].length == 4 ? parts[2] : '20${parts[2]}';
            veri.tarih = '${_ikiHane(parts[0])}-${_ikiHane(parts[1])}-$yil';
            break;
          }
        }
      }
    }

    // Saat tek yakalanmışsa:
    if (veri.zaman.isEmpty) {
      final saatler = RegExp(r'\b[0-2]?\d[:.,][0-5]\d(?:[:.,][0-5]\d)?\b')
          .allMatches(tumMetin)
          .map((m) => m.group(0)!)
          .toList();
      for (final s in saatler) {
        if (s.contains(':') || s.contains('.') || s.contains(',')) {
          final temiz = s.replaceAll(RegExp(r'[,.]'), ':');
          veri.zaman = temiz.length > 8 ? temiz.substring(0, 8) : temiz;
          break;
        }
      }
    }

    // -------------------------------------------------------------
    // 3. BASINÇ DAYANIM SINIFI (Örn: C35)
    // -------------------------------------------------------------
    final mCCift = RegExp(
      r'\b(c\s*\d{2}\s*[/\\|!]\s*\d{2})\b',
      caseSensitive: false,
    ).firstMatch(tumMetin);

    if (mCCift != null) {
      veri.dayanim = mCCift
          .group(1)!
          .replaceAll(RegExp(r'\s+'), '')
          .toUpperCase()
          .replaceAll('\\', '/')
          .replaceAll('|', '/')
          .replaceAll('!', '/');
    } else {
      final mCTek =
          RegExp(r'\b(c\s*\d{2})\b', caseSensitive: false).firstMatch(tumMetin);
      if (mCTek != null) {
        veri.dayanim =
            mCTek.group(1)!.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      }
    }

    // -------------------------------------------------------------
    // 4. ARAÇ PLAKASI (Örn: Mo1oo 34 HUB 101)
    // -------------------------------------------------------------
    const anahtarKelimeler = ['mikser', 'plaka', 'mo1', 'm01'];
    final plakaDeseni = RegExp(r'\b([0-8][0-9O]\s*[A-Z]{1,3}\s*[0-9O]{2,4})\b');

    for (var i = 0; i < satirlar.length; i++) {
      final sKucuk = satirlar[i].toLowerCase();
      if (anahtarKelimeler.any((k) => sKucuk.contains(k))) {
        final sonIndeks = (i + 3 < satirlar.length) ? i + 3 : satirlar.length;
        final hedef = satirlar.sublist(i, sonIndeks).join(' ').toUpperCase();
        final mPlk = plakaDeseni.firstMatch(hedef);
        if (mPlk != null) {
          final temizP = mPlk.group(1)!.replaceAll('O', '0');
          final rakamsizMi = !RegExp(r'^\d+$').hasMatch(temizP.replaceAll(' ', ''));
          if (!temizP.startsWith('C') && rakamsizMi) {
            veri.plaka = temizP.replaceAll(RegExp(r'\s+'), ' ').trim();
            break;
          }
        }
      }
    }

    if (veri.plaka.isEmpty) {
      final genelPlk = plakaDeseni
          .allMatches(tumMetin.toUpperCase())
          .map((m) => m.group(1)!)
          .toList();
      for (final p in genelPlk) {
        final temizP = p.replaceAll('O', '0');
        final rakamsizMi = !RegExp(r'^\d+$').hasMatch(temizP.replaceAll(' ', ''));
        if (!temizP.startsWith('C') && rakamsizMi) {
          veri.plaka = temizP.replaceAll(RegExp(r'\s+'), ' ').trim();
          break;
        }
      }
    }

    // -------------------------------------------------------------
    // 5. BETON MİKTARI (Örn: 5.5m3)
    // -------------------------------------------------------------
    for (var i = 0; i < satirlar.length; i++) {
      if (satirlar[i].toLowerCase().contains('beton miktar')) {
        final sonIndeks = (i + 3 < satirlar.length) ? i + 3 : satirlar.length;
        final hedef = satirlar.sublist(i, sonIndeks).join(' ');
        final mMiktar = RegExp(r'(\d+[.,]\d+|\d+)\s*(?:m3|m³)?').firstMatch(hedef);
        if (mMiktar != null) {
          final val = double.tryParse(mMiktar.group(1)!.replaceAll(',', '.'));
          if (val != null && val >= 1.0 && val <= 20.0) {
            veri.uretimMiktari = _sayiYaziyaCevir(val);
            break;
          }
        }
      }
    }

    if (veri.uretimMiktari.isEmpty) {
      final m3Eslesme = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(?:m3|m³)',
        caseSensitive: false,
      ).allMatches(tumMetin).map((m) => m.group(1)!).toList();

      for (final valStr in m3Eslesme) {
        final val = double.tryParse(valStr.replaceAll(',', '.'));
        if (val != null && val >= 1.0) {
          veri.uretimMiktari = _sayiYaziyaCevir(val);
          break;
        }
      }
    }

    return veri;
  }

  static String _ikiHane(String rakam) {
    final n = int.tryParse(rakam) ?? 0;
    return n.toString().padLeft(2, '0');
  }

  /// Python'daki `str(float)` davranışını taklit eder: 5.0 -> "5.0".
  static String _sayiYaziyaCevir(double val) {
    if (val == val.roundToDouble()) {
      return val.toStringAsFixed(1);
    }
    return val.toString();
  }
}
