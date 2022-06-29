from io import BytesIO
from unittest import TestCase

import rsilk

import pysilk


class TestEncode(TestCase):
    def setUp(self) -> None:
        with open("input.pcm", "rb") as f:
            self.test_pcm = f.read()
        with open("output.silk", "rb") as f:
            self.test_silk = f.read()

    def test_encode(self):
        rs_data = rsilk.encode(self.test_pcm, 24000, 24000)

        out = BytesIO()
        pysilk.encode(BytesIO(self.test_pcm), out, 24000, 24000)

        cy_data = out.getvalue()

        self.assertEqual(rs_data, cy_data)

    def test_decode(self):
        rs_data = rsilk.decode(self.test_silk, 24000)
        out = BytesIO()
        inp = BytesIO(self.test_silk)
        pysilk.decode(inp, out, 24000)
        cy_data = out.getvalue()
        self.assertEqual(rs_data, cy_data)


if __name__ == "__main__":
    import unittest

    unittest.main()
