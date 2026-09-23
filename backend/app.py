import os
import shlex
import subprocess
import tempfile
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import Response

app = FastAPI(title="Sefim CAD Converter")
ALLOWED_EXTENSIONS = {".dwg", ".dxf"}


@app.post("/convert")
async def convert(file: UploadFile = File(...)):
    extension = Path(file.filename or "").suffix.lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=415, detail="Yalnızca DWG veya DXF kabul edilir.")

    command_template = os.getenv("DWG_TO_PDF_COMMAND")
    if not command_template:
        raise HTTPException(
            status_code=503,
            detail="DWG_TO_PDF_COMMAND ayarlanmamış. Sunucuya bir DWG/PDF converter bağlayın.",
        )

    with tempfile.TemporaryDirectory(prefix="sefim-cad-") as directory:
        root = Path(directory)
        input_path = root / f"input{extension}"
        output_path = root / "output.pdf"
        input_path.write_bytes(await file.read())

        command = _build_command(command_template, input_path, output_path)
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
            raise HTTPException(status_code=504, detail="CAD dönüşümü zaman aşımına uğradı.") from error
        except OSError as error:
            raise HTTPException(status_code=500, detail="CAD converter çalıştırılamadı.") from error

        if result.returncode != 0 or not output_path.is_file():
            detail = result.stderr.strip()[-1000:] or "Converter PDF üretemedi."
            raise HTTPException(status_code=422, detail=detail)

        return Response(
            content=output_path.read_bytes(),
            media_type="application/pdf",
            headers={"Content-Disposition": 'inline; filename="project.pdf"'},
        )


def _build_command(template: str, input_path: Path, output_path: Path) -> list[str]:
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