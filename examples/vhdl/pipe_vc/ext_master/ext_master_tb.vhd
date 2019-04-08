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

entity ext_master_tb is
  generic (
    runner_cfg : string := "";
    encoded_tb_cfg : string := ""
  );
end entity;

architecture bench of ext_master_tb is
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
            wrpipe0_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_master/master0_wrpipe",
            rdpipe0_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_master/master0_rdpipe",
            wrpipe1_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_master/master1_wrpipe",
            rdpipe1_path => "/home/slawek/git/github/vunit/examples/vhdl/pipe_vc/ext_master/master1_rdpipe"
    );
  end function decode;
  constant tb_cfg : tb_cfg_t := decode(encoded_tb_cfg);

  signal clk    : std_logic := '0';
  signal rst    : std_logic := '0';
  constant tb_logger : logger_t := get_logger("tb");
  signal ext_master0_address    : std_logic_vector(tb_cfg.addr_width-1 downto 0);
  signal ext_master0_writedata  : std_logic_vector(tb_cfg.data_width-1 downto 0);
  signal ext_master0_readdata  : std_logic_vector(tb_cfg.data_width-1 downto 0);
  signal ext_master0_byteenable   : std_logic_vector(tb_cfg.data_width/8 -1 downto 0);
  signal ext_master0_burstcount : std_logic_vector(tb_cfg.burst_width -1 downto 0);
  signal ext_master0_write   : std_logic := '0';
  signal ext_master0_read   : std_logic := '0';
  signal ext_master0_readdatavalid : std_logic := '0';
  signal ext_master0_waitrequest    : std_logic := '0';

  constant ext_master0_pipe_logger : logger_t := get_logger("pipe0");
  constant ext_master0_master_actor : actor_t := new_actor("Avalon-MM Master - Ext Master0");
  constant ext_master0_master_logger : logger_t := get_logger("master0");
  constant ext_master0_bus_handle : bus_master_t := new_bus(
      data_length => tb_cfg.data_width,
      address_length => tb_cfg.addr_width, logger => ext_master0_master_logger,
      actor => ext_master0_master_actor);

  constant ext_master0_slave_memory : memory_t := new_memory;
  constant ext_master0_buf :  buffer_t := allocate(ext_master0_slave_memory, 1024);
  constant ext_master0_avalon_slave : avalon_slave_t := new_avalon_slave(
    memory => ext_master0_slave_memory,
    name => "Avalon-MM Slave - Ext Master0"
  );

  signal ext_master1_address    : std_logic_vector(tb_cfg.addr_width-1 downto 0);
  signal ext_master1_writedata  : std_logic_vector(tb_cfg.data_width-1 downto 0);
  signal ext_master1_readdata  : std_logic_vector(tb_cfg.data_width-1 downto 0);
  signal ext_master1_byteenable   : std_logic_vector(tb_cfg.data_width/8 -1 downto 0);
  signal ext_master1_burstcount : std_logic_vector(tb_cfg.burst_width -1 downto 0);
  signal ext_master1_write   : std_logic := '0';
  signal ext_master1_read   : std_logic := '0';
  signal ext_master1_readdatavalid : std_logic := '0';
  signal ext_master1_waitrequest    : std_logic := '0';

  constant ext_master1_pipe_logger : logger_t := get_logger("pipe1");
  constant ext_master1_master_actor : actor_t := new_actor("Avalon-MM Master - Ext Master1");
  constant ext_master1_master_logger : logger_t := get_logger("master1");
  constant ext_master1_bus_handle : bus_master_t := new_bus(
      data_length => tb_cfg.data_width,
      address_length => tb_cfg.addr_width, logger => ext_master1_master_logger,
      actor => ext_master1_master_actor);

  constant ext_master1_slave_memory : memory_t := new_memory;
  constant ext_master1_buf :  buffer_t := allocate(ext_master1_slave_memory, 1024);
  constant ext_master1_avalon_slave : avalon_slave_t := new_avalon_slave(
    memory => ext_master1_slave_memory,
    name => "Avalon-MM Slave - Ext Master1"
  );

begin

  main_stim : process
    constant channel : actor_t := new_actor("Subscribe channel");
  begin
    test_runner_setup(runner, runner_cfg);
    set_format(display_handler, verbose, true);
    show(tb_logger, display_handler, verbose);
    info(tb_logger, "Start");
    if run("cmds from ext master") then
      subscribe(channel, ext_master0_master_actor);
      subscribe(channel, ext_master1_master_actor);
      await_pipe_close(net, channel);
      await_pipe_close(net, channel);
    end if;
    info(tb_logger, "Quit");
    test_runner_cleanup(runner);
  end process;
  test_runner_watchdog(runner, 10 us);


  --
  -- External master controlled from sw (connected to its local slave)
  --
  ext_master0_pipe_brdige: entity work.pipe_vc_bridge
    generic map (
        wrpipe_path => tb_cfg.wrpipe0_path,
        rdpipe_path => tb_cfg.rdpipe0_path,
        bus_handle =>  ext_master0_bus_handle,
        logger =>  ext_master0_pipe_logger,
        actor => ext_master0_master_actor
    )
    port map (
        clk => clk,
        rst => rst
    );

  ext_master0_master : entity work.avalon_master
    generic map (
      bus_handle =>  ext_master0_bus_handle
    )
    port map (
      clk   => clk,
      address => ext_master0_address,
      byteenable => ext_master0_byteenable,
      burstcount => ext_master0_burstcount,
      write => ext_master0_write,
      writedata => ext_master0_writedata,
      read => ext_master0_read,
      readdata => ext_master0_readdata,
      readdatavalid => ext_master0_readdatavalid,
      waitrequest => ext_master0_waitrequest
    );

  ext_master0_slave : entity work.avalon_slave
    generic map (
      avalon_slave =>  ext_master0_avalon_slave
    )
    port map (
      clk   => clk,
      address => ext_master0_address,
      byteenable => ext_master0_byteenable,
      burstcount => ext_master0_burstcount,
      write => ext_master0_write,
      writedata => ext_master0_writedata,
      read => ext_master0_read,
      readdata => ext_master0_readdata,
      readdatavalid => ext_master0_readdatavalid,
      waitrequest => ext_master0_waitrequest
    );

  -- Master1
  ext_master1_pipe_brdige: entity work.pipe_vc_bridge
    generic map (
        wrpipe_path => tb_cfg.wrpipe1_path,
        rdpipe_path => tb_cfg.rdpipe1_path,
        bus_handle =>  ext_master1_bus_handle,
        logger =>  ext_master1_pipe_logger,
        actor => ext_master1_master_actor
    )
    port map (
        clk => clk,
        rst => rst
    );

  ext_master1_master : entity work.avalon_master
    generic map (
      bus_handle =>  ext_master1_bus_handle
    )
    port map (
      clk   => clk,
      address => ext_master1_address,
      byteenable => ext_master1_byteenable,
      burstcount => ext_master1_burstcount,
      write => ext_master1_write,
      writedata => ext_master1_writedata,
      read => ext_master1_read,
      readdata => ext_master1_readdata,
      readdatavalid => ext_master1_readdatavalid,
      waitrequest => ext_master1_waitrequest
    );

  ext_master1_slave : entity work.avalon_slave
    generic map (
      avalon_slave =>  ext_master1_avalon_slave
    )
    port map (
      clk   => clk,
      address => ext_master1_address,
      byteenable => ext_master1_byteenable,
      burstcount => ext_master1_burstcount,
      write => ext_master1_write,
      writedata => ext_master1_writedata,
      read => ext_master1_read,
      readdata => ext_master1_readdata,
      readdatavalid => ext_master1_readdatavalid,
      waitrequest => ext_master1_waitrequest
    );

  clk <= not clk after 5 ns;

end architecture;
