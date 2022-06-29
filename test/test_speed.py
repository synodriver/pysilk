import time
from io import BytesIO

import rsilk

import pysilk


def encode(times: int):
    with open("input.pcm", "rb") as f:
        test_pcm = f.read()
    with open("output.silk", "rb") as f:
        test_silk = f.read()
    start = time.time()
    for i in range(times):
        rsilk.encode(test_pcm, 24000, 24000)
    print(f"rsilk cost {time.time() - start}")

    start = time.time()
    for i in range(times):
        pysilk.encode(BytesIO(test_pcm), BytesIO(), 24000, 24000)
    print(f"pysilk cost {time.time() - start}")


def decode(times: int):
    with open("input.pcm", "rb") as f:
        test_pcm = f.read()
    with open("output.silk", "rb") as f:
        test_silk = f.read()
    start = time.time()
    for i in range(times):
        rsilk.decode(test_silk, 24000)
    print(f"rsilk cost {time.time() - start}")

    start = time.time()
    for i in range(times):
        pysilk.decode(BytesIO(test_silk), BytesIO(), 24000)
    print(f"pysilk cost {time.time() - start}")


encode(10)

# decode(10)
