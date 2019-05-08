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

entity pipe_vc_slave is
    generic (
        actor : actor_t;
        data_length : positive;
        address_length : positive;
        wrpipe_path : string;
        rdpipe_path : string;
        logger : logger_t
    );
    port (
        clk : in std_ulogic;
        rst : in std_ulogic
    );
end entity;

architecture bridge of pipe_vc_slave is

begin

  main : process
    file wp : bin_file_t;
    file rp : bin_file_t;
    variable f_status: file_open_status;
    variable data : std_ulogic_vector(data_length-1 downto 0);
    variable addr : std_ulogic_vector(address_length-1 downto 0);
    constant bus_data_bytes : positive := data_length/8;
    constant bus_addr_bytes : positive := address_length/8;
    variable request_msg : msg_t;
    variable msg_type : msg_type_t;
    variable ack : std_ulogic_vector(7 downto 0);
  begin
    file_open(f_status, wp, wrpipe_path, read_mode);
    assert f_status = open_ok severity error;
    file_open(f_status, rp, rdpipe_path, write_mode);
    assert f_status = open_ok severity error;
    pipe_loop: loop
        wait until rising_edge(clk) and rst = '0';
        receive(net, actor, request_msg);
        msg_type := message_type(request_msg);
        if msg_type = bus_write_msg then
            addr := pop_std_ulogic_vector(request_msg);
            data := pop_std_ulogic_vector(request_msg);
            write_bytes(rp, WR_CMD);
            write_bytes(rp, addr);
            write_bytes(rp, data);
            flush(rp);
            ack := read_bytes(wp, 1);
            assert ack = WR_ACK severity failure;
        -- TODO read msg
        else
            unexpected_msg_type(msg_type);
        end if;
    end loop;
    file_close(wp);
    file_close(rp);
    wait;
    end process;
end architecture;
