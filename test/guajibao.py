# -*- coding: utf-8 -*-
import asyncio
import random


class KumProtocol(asyncio.Protocol):
    def __init__(self, loop: asyncio.AbstractEventLoop):
        self._loop = loop
        self._transport: asyncio.Transport = None
        self._get_waiter: asyncio.Future = None
        self._closed: asyncio.Future = self._loop.create_future()

    def connection_made(self, transport):
        self._transport = transport

    def connection_lost(self, exc):
        if not self._closed.done():
            if exc is None:
                self._closed.set_result(None)
            else:
                self._closed.set_exception(exc)
        super().connection_lost()

    def data_received(self, data: bytes) -> None:
        if self._get_waiter is not None:
            self._get_waiter.set_result(data)

    def inc(self):
        self._transport.write("启动".encode("gbk"))

    def dec(self):
        self._transport.write("退出".encode("gbk"))

    async def get(self):
        assert self._get_waiter is None
        self._get_waiter = self._loop.create_future()
        try:
            self._transport.write("取回".encode("gbk"))
            data: bytes = await self._get_waiter
            return data.decode()
        finally:
            self._get_waiter = None

    def close(self):
        return self._transport.close()

    async def wait_closed(self):
        await self._closed

    def is_closing(self):
        return self._transport.is_closing()


async def task():
    reader, writer = await asyncio.open_connection("nanjing.guajibao.fun", 37192)
    while True:
        writer.write(bytes.fromhex("c6f4b6afc8a1bbd8"))
        await writer.drain()
        writer.write(bytes.fromhex("cdcbb3f6"))
        await writer.drain()
        print(f"在线: {await reader.read()}")
        await asyncio.sleep(random.randint(0, 5))


async def new_tasks():
    tasks = 0
    while True:
        asyncio.get_running_loop().create_task(task())
        print(f"连接数 {tasks}")
        tasks += 1


async def get():
    loop = asyncio.get_running_loop()
    transport, protocol = await loop.create_connection(lambda: KumProtocol(loop),"nanjing.guajibao.fun", 37192)
    print(await protocol.get())


asyncio.get_event_loop().run_until_complete(get())
