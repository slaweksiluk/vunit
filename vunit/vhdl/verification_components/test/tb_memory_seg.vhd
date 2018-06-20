-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2018, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;

use work.memory_pkg.all;

entity tb_memory_seg is
  generic (runner_cfg : string := runner_cfg_default);
end entity;

architecture a of tb_memory_seg is
begin

  main : process
    variable memory : memory_t;
    variable buf : buffer_t;
  begin
    test_runner_setup(runner, runner_cfg);

    if run("Test 1MB alloc") then
      memory := new_memory;
      buf := allocate(memory, 1024*1024);

    end if;
    test_runner_cleanup(runner);
  end process;
end architecture;
