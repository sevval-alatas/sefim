import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Native C Wrapper İmzaları (convert_dwg_to_dxf)
typedef ConvertDwgToDxfNative = ffi.Int Function(
    ffi.Pointer<Utf8> inputPath, ffi.Pointer<Utf8> outputPath);
typedef ConvertDwgToDxfDart = int Function(
    ffi.Pointer<Utf8> inputPath, ffi.Pointer<Utf8> outputPath);

/// Native C/C++ FFI köprüsü.
class LibreDwgFfi {
  static ffi.DynamicLibrary? _lib;
  static ConvertDwgToDxfDart? _convertWrapper;
  static bool _initialized = false;

  static ffi.DynamicLibrary? _loadLibrary() {
    if (_lib != null) return _lib;

    final libraryNames = <String>[];
    if (Platform.isAndroid) {
      libraryNames.addAll(['libdwg_converter.so', 'libredwg.so']);
    } else if (Platform.isIOS) {
      libraryNames.add(''); // iOS'ta ffi.DynamicLibrary.process() kullanılır
    } else if (Platform.isMacOS) {
      libraryNames.addAll(['libdwg_converter.dylib', 'libredwg.dylib']);
    } else if (Platform.isWindows) {
      libraryNames.addAll(['dwg_converter.dll', 'libredwg.dll']);
    } else if (Platform.isLinux) {
      libraryNames.addAll(['libdwg_converter.so', 'libredwg.so']);
    }

    for (final libName in libraryNames) {
      try {
        if (libName.isEmpty) {
          _lib = ffi.DynamicLibrary.process();
        } else {
          _lib = ffi.DynamicLibrary.open(libName);
        }

        if (_lib != null) {
          try {
            _convertWrapper = _lib!.lookupFunction<ConvertDwgToDxfNative, ConvertDwgToDxfDart>('convert_dwg_to_dxf');
            if (_convertWrapper != null) {
              _initialized = true;
              debugPrint('LibreDWG Native C Wrapper kütüphanesi yüklendi: ${libName.isEmpty ? 'process()' : libName}');
              break;
            }
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('LibreDWG kütüphanesi (${libName.isEmpty ? 'process()' : libName}) yüklenemedi: $e');
      }
    }
    return _lib;
  }

  /// Native C Wrapper (convert_dwg_to_dxf) çağırarak DWG dosyasını yerel olarak DXF dosyasına dönüştürür.
  static bool convertDwgToDxf(String dwgPath, String dxfPath) {
    _loadLibrary();
    if (!_initialized || _convertWrapper == null) {
      return false;
    }

    ffi.Pointer<Utf8> dwgPathPtr = ffi.nullptr;
    ffi.Pointer<Utf8> dxfPathPtr = ffi.nullptr;

    try {
      dwgPathPtr = dwgPath.toNativeUtf8();
      dxfPathPtr = dxfPath.toNativeUtf8();

      final res = _convertWrapper!(dwgPathPtr, dxfPathPtr);
      debugPrint(
        '========== LibreDWG ==========\n'
        'Input : $dwgPath\n'
        'Output: $dxfPath\n'
        'Result: $res\n'
        '==============================',
      );
      return res == 0;
    } catch (e, st) {
      debugPrint('LibreDWG FFI istisnası: $e\n$st');
      return false;
    } finally {
      if (dwgPathPtr != ffi.nullptr) calloc.free(dwgPathPtr);
      if (dxfPathPtr != ffi.nullptr) calloc.free(dxfPathPtr);
    }
  }
}
