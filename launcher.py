import sys
import os

def resource_path(rel):
    base = getattr(sys, "_MEIPASS", os.path.dirname(os.path.abspath(sys.executable)))
    return os.path.join(base, rel)


def exe_dir():
    return os.path.dirname(os.path.abspath(sys.executable))

os.environ.setdefault("MODELS_DIR", resource_path("models"))

from dotenv import load_dotenv
load_dotenv(os.path.join(exe_dir(), ".env"), override=False)

from app.server import build_server

if __name__ == "__main__":
    build_server().run()