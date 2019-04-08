# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

from os.path import dirname
from vunit import VUnit
from threading import Thread
from stim import master_stim


def make_pre_call(p):
    def pre_call(output_path):
        p.start()
        return True
    return pre_call


def make_post_call(p):
    def post_call(output_path):
        p.join(1)
        if p.is_alive():
            print('thread stuck - force exit')
            return False
        else:
            return True
    return post_call


root = dirname(__file__)
ui = VUnit.from_argv()
ui.add_verification_components()
ui.add_compile_option("ghdl.flags", ["-g"])
lib = ui.library("vunit_lib")
lib.add_source_files("*.vhd")
p = Thread(target=master_stim)
tb = lib.test_bench("ext_master_tb")
tb.set_pre_config(make_pre_call(p))
tb.set_post_check(make_post_call(p))
ui.main()
