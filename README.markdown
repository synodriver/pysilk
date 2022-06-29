<h1 align="center"><i>✨ pysilk ✨ </i></h1>

<h3 align="center">The python binding for <a href="https://github.com/kn007/silk-v3-decoder">silk-v3-decoder</a> </h3>

[![pypi](https://img.shields.io/pypi/v/silk-python.svg)](https://pypi.org/project/silk-python/)
![python](https://img.shields.io/pypi/pyversions/silk-python)
![implementation](https://img.shields.io/pypi/implementation/silk-python)
![wheel](https://img.shields.io/pypi/wheel/silk-python)
![license](https://img.shields.io/github/license/synodriver/pysilk.svg)
![action](https://img.shields.io/github/workflow/status/synodriver/pysilk/build%20wheel)

## 安装
```bash
pip install silk-python
```


## 使用
- encode
```python
import pysilk

with open("verybiginput.pcm", "rb") as pcm, open("output.silk", "wb") as silk:
    pysilk.encode(pcm, silk, 24000, 24000)
```

- decode

```python
import pysilk

with open("verybiginput.silk", "rb") as silk, open("output.pcm", "wb") as pcm:
    pysilk.decode(silk, pcm, 24000)
```

## 支持功能
- 接受任何二进制的```file-like object```，比如```BytesIO```，可以流式解码大文件
- 包装了silk的全部C接口的参数，当然他们都有合理的默认值
- 基于```Cython```， [关键部位](https://github.com/synodriver/pysilk/blob/stream/pysilk/silk.pxd#L43-L65) 内联C函数，高性能


## 公开函数
```python
from typing import BinaryIO

def encode(input: BinaryIO, output: BinaryIO, sample_rate: int, bit_rate: int, max_internal_sample_rate: int = 24000, packet_loss_percentage: int = 0, complexity: int = 2, use_inband_fec: bool = False, use_dtx: bool = False, tencent: bool = True) -> bytes: ...
def decode(input: BinaryIO, output: BinaryIO, sample_rate: int, frame_size: int = 0, frames_per_packet: int = 1, more_internal_decoder_frames: bool = False, in_band_fec_offset: int = 0, loss: bool = False) -> bytes: ...
```

## 公开异常
```python
class SilkError(Exception):
    pass
```

### ✨v0.2.0✨
合并了[CFFI](https://github.com/synodriver/pysilk-cffi) 的工作

### 本机编译
```
python -m pip install setuptools wheel cython cffi
git clone https://github.com/synodriver/pysilk
cd pysilk
git submodule update --init --recursive
python setup.py bdist_wheel --use-cython --use-cffi
```

### 后端选择
默认由py实现决定，在cpython上自动选择cython后端，在pypy上自动选择cffi后端，使用```SILK_USE_CFFI```环境变量可以强制选择cffi