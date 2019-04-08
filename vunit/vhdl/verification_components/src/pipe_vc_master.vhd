-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

use std.textio.all;

context work.vunit_context;
context work.com_context;
use work.avalon_pkg.all;
use work.bus_master_pkg.all;
use work.pipe_bridge_pkg.all;

entity pipe_vc_bridge is
    generic (
        actor : actor_t;
        wrpipe_path : string;
        rdpipe_path : string;
        bus_handle : bus_master_t;
        logger : logger_t
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic
    );
end entity;

architecture bridge of pipe_vc_bridge is

begin

  main : process
    file wp : bin_file_t;
    file rp : bin_file_t;
    variable f_status: file_open_status;
    variable data : std_ulogic_vector(data_length(bus_handle)-1 downto 0);
    variable addr : std_ulogic_vector(address_length(bus_handle)-1 downto 0);
    variable cmd : std_ulogic_vector(7 downto 0);
    constant bus_data_bytes : positive := data_length(bus_handle)/8;
    constant bus_addr_bytes : positive := address_length(bus_handle)/8;
    variable msg : msg_t;
  begin
      file_open(f_status, wp, wrpipe_path, read_mode);
      assert f_status = open_ok severity error;
      file_open(f_status, rp, rdpipe_path, write_mode);
      assert f_status = open_ok severity error;
      pipe_loop: loop
      wait until rising_edge(clk) and rst = '0';
      if not endfile(wp) then
          cmd := read_bytes(wp, 1);
          case cmd is
          when WR_CMD =>
            addr := read_bytes(wp, bus_addr_bytes);
            data := read_bytes(wp, bus_data_bytes);
            debug(logger, "wr addr = "&to_hstring(addr));
            debug(logger, "wr data = "&to_hstring(data));
            write_bus(net, bus_handle, addr, data);
            wait_until_idle(net, bus_handle);
          when RD_CMD =>
            addr := read_bytes(wp, bus_addr_bytes);
            read_bus(net, bus_handle, addr, data);
            wait_until_idle(net, bus_handle);
            debug(logger, "rd addr = "&to_hstring(addr));
            debug(logger, "rd data = "&to_hstring(data));
            write_bytes(rp, data);
            flush(rp);
          when FINISH_CMD =>
            info(logger, "got finish cmd");
            exit pipe_loop;
          when others =>
            error("Unsupported cmd");
        end case;
      end if;
      end loop;
      file_close(wp);
      file_close(rp);
      msg := new_msg(pipe_closed_msg);
      publish(net, actor, msg);
      wait;
  end process;


end architecture;
