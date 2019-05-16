# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

from os.path import dirname
from vunit import VUnit, BusRunner
from threading import Thread
from stim import master_stim


def make_pre_call():
    def pre_call(output_path):
        BusRunner(master_stim, output_path)
        return True
    return pre_call


def make_post_call():
    def post_call(output_path):
        return BusRunner.seek(output_path)
    return post_call


root = dirname(__file__)
ui = VUnit.from_argv()
ui.add_verification_components()
ui.add_compile_option("ghdl.flags", ["-g"])
lib = ui.library("vunit_lib")
lib.add_source_files("*.vhd")
tb = lib.test_bench("ext_master_tb")
tb.set_pre_config(make_pre_call())
tb.set_post_check(make_post_call())
ui.main()
