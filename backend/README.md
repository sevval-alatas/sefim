# Sefim CAD converter backend

Bu servis DWG/DXF dosyasını alır ve bağlı CAD converter'ın ürettiği PDF'i döndürür.
DWG parser veya renderer içermez. Gerçek dönüşüm için ODA File Converter, Autodesk tabanlı bir servis veya kurumunuzun lisanslı converter'ı gerekir.

## Kurulum

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Converter komutu `{input}` ve `{output}` yer tutucularını kullanmalıdır. Komutun başarılı olduğunda `{output}` konumunda PDF üretmesi gerekir.

```bash
export DWG_TO_PDF_COMMAND='/opt/cad/bin/convert --input {input} --output {output}'
uvicorn app:app --host 0.0.0.0 --port 8000
```

Flutter Android emulator için varsayılan endpoint `http://10.0.2.2:8000/convert` adresidir. Fiziksel cihazda `lib/servis/cad_donusum_servisi.dart` içindeki adresi bilgisayarın yerel IP adresiyle değiştirin.