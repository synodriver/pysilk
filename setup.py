# -*- coding: utf-8 -*-
import os
import re
import shutil

from skbuild import setup
from Cython.Build import cythonize
from setuptools import Extension

extensions = [
    # Extension("api", ["silk/lowlevelapi.pyx"],
    #           include_dirs=["src"],
    #           libraries=["silk"],
    #           library_dirs=["./silk"],
    #           # extra_link_args=["-silk/silk.dll"]
    #           ),
    # # Everything but primes.pyx is included here.
    Extension("transcoder", ["silk/transcoder.pyx"],
              include_dirs=["src"],
              libraries=["silk"],
              library_dirs=["./silk"],
              # extra_link_args=["-silk/silk.dll"]
              ),
]


def get_dis():
    with open("README.markdown", "r", encoding="utf-8") as f:
        return f.read()


def get_version() -> str:
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), "silk", "__init__.py")
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    result = re.findall(r"(?<=__version__ = \")\S+(?=\")", data)
    return result[0]


# packages = find_packages(exclude=('test', 'tests.*', "test*"))
def move_file(dst: str):
    for file in os.listdir("."):
        if os.path.splitext(file)[-1] in (".so", ".dll", ".lib", ".pyd"):
            shutil.move(os.path.abspath(file), dst)


def main():
    version: str = get_version()

    dis = get_dis()
    setup(
        name="silk",
        version=version,
        url="https://github.com/synodriver/silk",
        packages=["silk"],
        keywords=["silk", "encode", "decode"],
        description="silk encode and decode",
        long_description_content_type="text/markdown",
        long_description=dis,
        author="synodriver",
        author_email="diguohuangjiajinweijun@gmail.com",
        python_requires=">=3.6",
        install_requires=["cython"],
        license='GPLv3',
        classifiers=[
            "Development Status :: 4 - Beta",
            "Operating System :: OS Independent",
            "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
            "Topic :: Multimedia :: Sound/Audio",
            "Programming Language :: C",
            "Programming Language :: Cython",
            "Programming Language :: Python",
            "Programming Language :: Python :: 3.6",
            "Programming Language :: Python :: 3.7",
            "Programming Language :: Python :: 3.8",
            "Programming Language :: Python :: 3.9",
            "Programming Language :: Python :: Implementation :: CPython"
        ],
        include_package_data=True,
        zip_safe=True,
        ext_modules=cythonize(extensions),
    )
    move_file(os.path.join(os.path.dirname(__file__), "silk"))


if __name__ == "__main__":
    main()
