from unittest import TestCase
from io import BytesIO

import rsilk
import pysilk


class TestEncode(TestCase):
    def setUp(self) -> None:
        with open("input.pcm", "rb") as f:
            self.test_data = f.read()

    def test_encode(self):
        rs_data = rsilk.encode(self.test_data, 24000, 24000)

        out = BytesIO()
        pysilk.encode(BytesIO(self.test_data), out, 24000, 24000)

        cy_data = out.getvalue()

        self.assertEqual(rs_data, cy_data)
