# -*- coding: utf-8 -*-
import os
import re
import glob
from collections import defaultdict

from Cython.Build import cythonize
from setuptools import Extension, setup, find_packages
from setuptools.command.build_ext import build_ext

BUILD_ARGS = defaultdict(lambda: ['-O3', '-g0'])

for compiler, args in [
    ('msvc', ['/EHsc', '/DHUNSPELL_STATIC', "/Oi", "/O2", "/Ot"]),
    ('gcc', ['-O3', '-g0'])]:
    BUILD_ARGS[compiler] = args


class build_ext_compiler_check(build_ext):
    def build_extensions(self):
        compiler = self.compiler.compiler_type
        args = BUILD_ARGS[compiler]
        for ext in self.extensions:
            ext.extra_compile_args = args
        super().build_extensions()


extensions = [
    Extension("pysilk._silk", ["pysilk/_silk.pyx"] + glob.glob('./src/*.c'),
              include_dirs=["./src"],
              library_dirs=["./src"],
              ),
]


def get_dis():
    with open("README.markdown", "r", encoding="utf-8") as f:
        return f.read()


def get_version() -> str:
    path = os.path.join(os.path.abspath(os.path.dirname(__file__)), "pysilk", "__init__.py")
    with open(path, "r", encoding="utf-8") as f:
        data = f.read()
    result = re.findall(r"(?<=__version__ = \")\S+(?=\")", data)
    return result[0]


packages = find_packages(exclude=('test', 'tests.*', "test*"))


def main():
    version: str = get_version()

    dis = get_dis()
    setup(
        name="silk-python",
        version=version,
        url="https://github.com/synodriver/pysilk",
        packages=packages,
        keywords=["silk", "encode", "decode", "pcm", "audio"],
        description="silk encode and decode",
        long_description_content_type="text/markdown",
        long_description=dis,
        author="synodriver",
        author_email="diguohuangjiajinweijun@gmail.com",
        python_requires=">=3.6",
        install_requires=["cython"],
        license='BSD',
        classifiers=[
            "Development Status :: 4 - Beta",
            "Operating System :: OS Independent",
            "License :: OSI Approved :: BSD License",
            "Topic :: Multimedia :: Sound/Audio",
            "Programming Language :: C",
            "Programming Language :: Cython",
            "Programming Language :: Python",
            "Programming Language :: Python :: 3.6",
            "Programming Language :: Python :: 3.7",
            "Programming Language :: Python :: 3.8",
            "Programming Language :: Python :: 3.9",
            "Programming Language :: Python :: 3.10",
            "Programming Language :: Python :: Implementation :: CPython"
        ],
        include_package_data=True,
        zip_safe=False,
        cmdclass={'build_ext': build_ext_compiler_check},
        ext_modules=cythonize(extensions,
                              compiler_directives={"cdivision": True,
                                                   "embedsignature": True,
                                                   "boundscheck": False,
                                                   "wraparound": False}),
    )


if __name__ == "__main__":
    main()
