#!/usr/bin/env python3
"""DWG to DXF dönüştürücü CLI aracı"""

import os
import shlex
import subprocess
import tempfile
from pathlib import Path


def convert_file(input_path: Path, output_path: Path, command_template: str) -> bool:
    """DWG dosyasını DXF'e dönüştürür."""
    
    with tempfile.TemporaryDirectory(prefix="sefim-cad-") as directory:
        root = Path(directory)
        input_file = root / f"input{input_path.suffix}"
        output_file = root / "output.dxf"
        
        # Girdi dosyasını kopyala
        input_file.write_bytes(input_path.read_bytes())
        
        # DXF başlığını ekle (header eklemesi)
        dxf_header = "HEADER *DWG;Version 12"  # DXF başlığını ekle
        
        # Converter'ı çalıştır
        command = _build_command(command_template, input_file, output_file)
        try:
            result = subprocess.run(
                command,
                cwd=root,
                capture_output=True,
                text=True,
                timeout=300,
                check=False,
            )
        except subprocess.TimeoutExpired as error:
            print("❌ Hata: CAD dönüşümü zaman aşımına uğradı.")
            print(f"Stderr: {result.stderr}")
            return False
        except OSError as error:
            print("❌ Hata: CAD converter çalıştırılamadı.")
            print(f"Stderr: {result.stderr}")
            return False

        if result.returncode != 0 or not output_file.is_file():
            error_msg = result.stderr.strip()[-1000:] or "Converter DXF üretemedi."
            print(f"❌ Hata: {error_msg}")
            return False
        
        # Başarılı - DXF dosyasını döndür
        dxf_content = output_file.read_text()
        print(f"✅ Başarılı! DXF dosyası oluşturuldu: {dxf_content[:200]}...")
        
        return dxf_content


def _build_command(template: str, input_path: Path, output_path: Path) -> list[str]:
    """Komut şablonunu değişkenlerle doldurur."""
    values = {
        "{input}": str(input_path),
        "{output}": str(output_path),
        "{input_dir}": str(input_path.parent),
        "{output_dir}": str(output_path.parent),
    }
    command = template
    for placeholder, value in values.items():
        command = command.replace(placeholder, value)
    return shlex.split(command)


def main():
    """Ana CLI fonksiyonu."""
    import sys
    
    if len(sys.argv) < 2:
        print("❌ Kullanım: python convert_dwg_to_dxf.py <girdi_dosyasi> <cikti_dosyasi>")
        print("   veya: python convert_dwg_to_dxf.py -h")
        print()
        print("   Örnek:")
        print("   python convert_dwg_to_dxf.py proje.dwg proje_dxf.dxf")
        print()
        print("   DXF içeriğini göstermek için: python convert_dwg_to_dxf.py <girdi_dosyasi>")
        print()
        sys.exit(1)
    
    input_arg = sys.argv[1]
    command_template = os.getenv("DWG_TO_DXF_COMMAND")
    
    if not command_template:
        print("❌ Hata: DWG_TO_DXF_COMMAND çevreci ayarlanmamış.")
        print("   Lütfen şu şekilde ayarlayın:")
        print("   export DWG_TO_DXF_COMMAND=\"komut_buraya\"")
        print()
        print("   Önerilen komutlar:")
        print("   - AutoCAD: acad \"{input}\" \"{output}\"")
        print("   - QCAD: qcad -t dxf \"{input}\" \"{output}\"")
        print("   - LibreCAD: libreoffice --convert-to dxf \"{input}\"")
        print()
        sys.exit(1)
    
    # İki arguman varsa (çıktı dosyası verilirse)
    if len(sys.argv) >= 3:
        output_arg = sys.argv[2]
        result = convert_file(Path(input_arg), Path(output_arg), command_template)
        if result:
            print(f"\n📄 DXF İçerik Gösterimi:")
            print("=" * 50)
            print(result)
        sys.exit(0 if result else 1)
    else:
        # Sadece girdi argümanı varsa, çıktı dosyasını otomatik adlandır
        output_file = Path(input_arg).with_suffix(".dxf")
        result = convert_file(Path(input_arg), output_file, command_template)
        if result:
            print(f"\n📄 DXF İçerik Gösterimi:")
            print("=" * 50)
            print(result)
            # DXF dosyasını da oluştur
            with open(output_file, "w", encoding="utf-8") as f:
                f.write(result)
        sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()