-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

context work.vunit_context;
context work.vc_context;
use work.pipe_bridge_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;

entity ext_slave_tb is
  generic (
    runner_cfg : string := "";
    encoded_tb_cfg : string := ""
  );
end entity;

architecture bench of ext_slave_tb is
  type tb_cfg_t is record
    data_width : positive;
    addr_width : positive;
    burst_width : positive;
    wrpipe0_path : string;
    rdpipe0_path : string;
    wrpipe1_path : string;
    rdpipe1_path : string;
  end record tb_cfg_t;

  impure function decode(encoded_tb_cfg : string) return tb_cfg_t is
  begin
    return (data_width => 32,
            addr_width => 32,
            burst_width => 1,
            wrpipe0_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_slave/wrpipe0",
            rdpipe0_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_slave/rdpipe0",
            wrpipe1_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_slave/wrpipe0",
            rdpipe1_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_slave/rdpipe0"
    );
  end function decode;
  constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  constant tb_logger : logger_t := get_logger("tb");

  constant pipe_slave_logger : logger_t := get_logger("pipe");
  constant pipe_slave_actor : actor_t := new_actor("External Slave");
  constant main_actor : actor_t := new_actor("Main");

begin

  main : process
    variable msg : msg_t;
    variable data : std_ulogic_vector(tb_cfg.data_width-1 downto 0);
    variable addr : std_ulogic_vector(tb_cfg.addr_width-1 downto 0);
  begin
    test_runner_setup(runner, runner_cfg);
    set_format(display_handler, verbose, true);
    show(tb_logger, display_handler, verbose);
    info(tb_logger, "Start");
    if run("write-to-slave") then
      wait until rising_edge(clk) and rst = '0';
      msg := new_msg(bus_write_msg);
      addr := x"00000004";
      data := x"ab8912fe";
      push(msg, addr);
      push(msg, data);
      send(net, pipe_slave_actor, msg);
      wait for 100 ns;
    end if;
    info(tb_logger, "Quit");
    -- wait;
    test_runner_cleanup(runner);
  end process;
  test_runner_watchdog(runner, 10 us);


  --
  -- External slave bridge passes transactions via pipes
  --
  ext_slave_bridge: entity work.pipe_vc_slave
    generic map (
        wrpipe_path => tb_cfg.wrpipe0_path,
        rdpipe_path => tb_cfg.rdpipe0_path,
        data_length => tb_cfg.data_width,
        address_length => tb_cfg.addr_width,
        logger => pipe_slave_logger,
        actor => pipe_slave_actor
    )
    port map (
        clk => clk,
        rst => rst
    );

  clk <= not clk after 5 ns;

end architecture;
