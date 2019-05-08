# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

from os.path import dirname, join
from vunit import VUnit
from threading import Thread
from vunit.pipe_vc import BusSlave
import time


root = dirname(__file__)


def make_pre_call(p):
    def pre_call(output_path):
        p.start()
        return True
    return pre_call


def make_post_call(p):
    def post_call(output_path):
        p.join(5)
        if p.is_alive():
            print('thread stuck - force exit')
            return False
        else:
            return True
    return post_call


def slave_stim():
    wrpipe_path = join(root, 'wrpipe0')
    rdpipe_path = join(root, 'rdpipe0')
    bus0 = BusSlave(wrpipe_path, rdpipe_path, 4, 4)
    addr, data = bus0.poll()
    print('Slave received following write:')
    print('addr'+hex(addr))
    print('data'+hex(data))
    assert addr == 0x04
    assert data == 0xab8912fe


ui = VUnit.from_argv()
ui.add_verification_components()
ui.add_compile_option("ghdl.flags", ["-g"])
lib = ui.library("vunit_lib")
lib.add_source_files("*.vhd")
p = Thread(target=slave_stim)
tb = lib.test_bench("ext_slave_tb")
tb.set_pre_config(make_pre_call(p))
tb.set_post_check(make_post_call(p))
ui.main()
