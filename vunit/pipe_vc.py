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
from threading import Thread, Lock, enumerate
import time

root = dirname(__file__)


class BusBase(object):
    WR_CMD = bytes.fromhex('00')
    RD_CMD = bytes.fromhex('01')
    FINISH_CMD = bytes.fromhex('02')
    WR_ACK = bytes.fromhex('03')

    def __init__(self, pipes_path, bus_id, addr_size, data_size):
        self.addr_size = addr_size
        self.data_size = data_size
        self.wrpipe_path = join(pipes_path, bus_id)+'_wrpipe'
        self.rdpipe_path = join(pipes_path, bus_id)+'_rdpipe'
        os.mkfifo(self.wrpipe_path)
        os.mkfifo(self.rdpipe_path)
        self.wp = open(self.wrpipe_path, 'wb')
        self.rp = open(self.rdpipe_path, 'rb')
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
        cmd = self.read_cmd()
        assert cmd == self.WR_ACK, 'Write acknowledge expected from dut, but received: '+str(cmd)

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
    def __init__(self, wrpipe_path, rdpipe_path, addr_size, data_size):
        super().__init__(wrpipe_path, rdpipe_path, addr_size, data_size)
        self.addr = None
        self.data = None
        self.wr_lock = Lock()
        self.p = Thread(target=self.target)
        self.p.start()

    def target(self):
        while 1:
            cmd = self.read_cmd()
            if cmd == self.WR_CMD:
                self.wr_lock.acquire()
                self.addr = self.read_addr()
                self.data = self.read_data()
                self.wr_lock.release()
            elif cmd == self.RD_CMD:
                raise ValueError('Slave read not (yet) implemented')
            elif cmd == b'':
                print('Received empty command byte (broken pipe?) exit...')
                break
            else:
                raise ValueError('Unknown command byte: '+str(cmd))

    def get(self):
        self.wr_lock.acquire()
        a = self.addr
        self.addr = None
        d = self.data
        self.data = None
        self.wr_lock.release()
        # Write acknowledge (only if data valid)
        if a is not None:
            self.write_ack()
        return a, d

    def poll(self):
        addr = None
        while addr is None:
            addr, data = self.get()
            time.sleep(1)
        return addr, data

    def __del__(self):
        self.p.join()

    def write_ack(self):
        self.wp.write(self.WR_ACK)
        try:
            self.wp.flush()
        except BrokenPipeError as err:
            print('OSError during flush:', err)
            pass


class BusRunner(Thread):
    def __init__(self, target, output_path, **kwargs):
        super().__init__()
        self.passed = None
        self.target = target
        self.output_path = output_path
        self.name = BusRunner.get_name(output_path)
        self.kwargs = kwargs
        self.start()

    def run(self):
        print('Default run method, run user target()')
        self.target(self)

    @staticmethod
    def seek(output_path):
        name = BusRunner.get_name(output_path)
        for p in enumerate():
            if p.name == name:
                print('Thread '+p.name+'is still running and reports status='+str(p.passed)+'. Await join()...')
                p.join(1)
                if p.is_alive():
                    RuntimeError('Thread '+name+' hang.')
                return p.passed
        RuntimeError('Thread '+name+' has not been found.')

    @staticmethod
    def get_name(output_path):
        return output_path[-8:]
