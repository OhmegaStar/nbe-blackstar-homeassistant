import socket

import pytest

import protocol
from frames import Request_frame


class TimeoutSocket:
    def bind(self, address):
        self.address = address

    def setsockopt(self, *args):
        pass

    def settimeout(self, timeout):
        self.timeout = timeout

    def sendto(self, data, address):
        self.sent = (data, address)

    def recvfrom(self, size):
        raise socket.timeout("simulated burner timeout")

    def close(self):
        pass


def test_proxy_surfaces_udp_timeout(monkeypatch):
    udp_socket = TimeoutSocket()
    monkeypatch.setattr(protocol.socket, "socket", lambda *args: udp_socket)

    with pytest.raises(socket.timeout, match="simulated burner timeout"):
        protocol.Proxy("123456789", port=8483, addr="192.0.2.1", serialnumber="123456")

    assert udp_socket.timeout == 5.0
    assert udp_socket.sent[1] == ("192.0.2.1", 8483)


def test_request_frame_contains_payload():
    request = Request_frame()
    request.controllerid = "123456"
    request.payload = "NBE Discovery"

    encoded = request.encode()

    assert encoded.endswith(b"NBE Discovery\x04")
    assert encoded[20:22] == b"00"