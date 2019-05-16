# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

from os.path import join, dirname
from vunit.pipe_vc import BusMaster
from time import sleep

root = dirname(__file__)


def master_stim(self):
    bus0 = BusMaster(self.output_path, 'BusMaster0', 4, 4)
    bus1 = BusMaster(self.output_path, 'BusMaster1', 4, 4)
    addr = 0x00
    data = 0x0a0b0c0d
    bus0.write(addr, data)
    rd_data = bus0.read(addr)
    assert rd_data == data, 'act='+hex(rd_data)+' exp='+hex(data)

    addr = 0x0C
    data = 0x23eebaaa
    bus0.write(addr, data)
    rd_data = bus0.read(addr)
    assert rd_data == data, 'act='+hex(rd_data)+' exp='+hex(data)

    addr = 0x08
    data = 0x412ac214
    bus1.write(addr, data)
    bus0.write(addr, data)
    rd_data = bus0.read(addr)
    rd_data = bus1.read(addr)
    assert rd_data == data, 'act='+hex(rd_data)+' exp='+hex(data)

    bus0.finish()
    bus1.finish()

    self.passed = True
    sleep(0.5)


if __name__ == "__main__":
    master_stim()
