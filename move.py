import os
import shutil


def move_file(dst: str):
    for file in os.listdir("."):
        if os.path.splitext(file)[-1] in (".so", ".dll", ".lib", ".pyd"):
            shutil.move(os.path.abspath(file), dst)


move_file(os.path.join(os.path.dirname(__file__), "silk"))
