"""后台配置和备份的原子文件写入。"""

import os
from pathlib import Path
import tempfile
import uuid


def atomic_write(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
            temporary = stream.name
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        temporary = None
    finally:
        if temporary is not None:
            os.unlink(temporary)


def backup(directory, data):
    path = Path(directory) / (uuid.uuid4().hex + ".json")
    atomic_write(path, data)
    return path.stem
