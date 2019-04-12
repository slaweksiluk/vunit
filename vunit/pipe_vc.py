# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

from os.path import join, dirname
from vunit import VUnit
from itertools import product
import os
import errno
import subprocess

root = dirname(__file__)


class BusBase(object):
    WR_CMD = bytes.fromhex('00')
    RD_CMD = bytes.fromhex('01')
    FINISH_CMD = bytes.fromhex('02')

    def __init__(self, wrpipe_path, rdpipe_path, addr_size, data_size):
        self.addr_size = addr_size
        self.data_size = data_size
        self.wp = open(wrpipe_path, 'wb')
        self.rp = open(rdpipe_path, 'rb')
        self.order = 'big'

    def as_bytes(self, d, n):
        return d.to_bytes(n, self.order)

    def addr_bytes(self, d):
        return self.as_bytes(d, self.addr_size)

    def data_bytes(self, d):
        return self.as_bytes(d, self.data_size)

    def read_byte_data(self):
        b = self.rp.read(self.data_size)
        return b

    def read_data(self):
        b = self.read_byte_data()
        return int.from_bytes(b, self.order)

    def read_addr(self):
        b = self.rp.read(self.addr_size)
        return int.from_bytes(b, self.order)

    def read_cmd(self):
        b = self.rp.read(1)
        return b


class BusMaster(BusBase):
    def finish(self):
        self.wp.write(self.FINISH_CMD)
        self.wp.flush()
        self.wp.close()
        self.rp.close()

    def write(self, addr, data):
        self.wp.write(self.WR_CMD)
        self.wp.write(self.addr_bytes(addr))
        self.wp.write(self.data_bytes(data))
        self.wp.flush()

    def read(self, addr):
        self.wp.write(self.RD_CMD)
        self.wp.write(self.addr_bytes(addr))
        self.wp.flush()
        return self.read_data()

    def read_bytes(self, addr):
        self.wp.write(self.RD_CMD)
        self.wp.write(self.addr_bytes(addr))
        self.wp.flush()
        return self.read_byte_data()


class BusSlave(BusBase):
    def get(self):
        cmd = self.read_cmd()
        if cmd == self.WR_CMD:
            addr = self.read_addr()
            data = self.read_data()
            return addr, data
        elif cmd == self.RD_CMD:
            raise "TODO"
        elif cmd == b'':
            raise ValueError('Received empty command byte')
        else:
            raise ValueError('Unknown command byte: '+str(cmd))
