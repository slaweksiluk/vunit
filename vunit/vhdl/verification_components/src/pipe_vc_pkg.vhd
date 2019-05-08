-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

context work.vunit_context;
context work.com_context;

package pipe_bridge_pkg is
    constant pipe_closed_msg : msg_type_t := new_msg_type("Pipe stim done");
    procedure await_pipe_close(signal net : inout network_t; channel : actor_t);

    constant WR_CMD : std_ulogic_vector(7 downto 0) := x"00";
    constant RD_CMD : std_ulogic_vector(7 downto 0) := x"01";
    constant FINISH_CMD : std_ulogic_vector(7 downto 0) := x"02";
    constant WR_ACK : std_ulogic_vector(7 downto 0) := x"03";
    type bin_file_t is file of character;

    impure function read_bytes (file f : bin_file_t; n : positive) return std_ulogic_vector;
    procedure write_bytes (file f : bin_file_t; data : std_ulogic_vector);

end package;
package body pipe_bridge_pkg is

    procedure await_pipe_close(signal net : inout network_t; channel : actor_t) is
      variable msg : msg_t;
      variable msg_type : msg_type_t;
    begin
      receive(net, channel, msg);
      msg_type := message_type(msg);
      if msg_type /= pipe_closed_msg then
        unexpected_msg_type(msg_type);
      end if;
    end procedure;

    impure function read_bytes (file f : bin_file_t; n : positive) return std_ulogic_vector is
        variable r : std_ulogic_vector(n*8-1 downto 0);
        variable c : character;
    begin
      for i in n-1 downto 0 loop
          read(f, c);
          r((i+1)*8-1 downto i*8) :=
              std_ulogic_vector((to_unsigned(character'pos(c), 8)));
      end loop;
      return r;
    end function;

    procedure write_bytes (file f : bin_file_t; data : std_ulogic_vector) is
      constant n : positive := data'length/8;
    begin
      assert data'length mod 8 = 0
      report "write_bytes() expects n bytes as input"
      severity failure;
      for i in n-1 downto 0 loop
          write (f, character'val(to_integer(unsigned(data((i+1)*8-1 downto i*8)))));
      end loop;
    end procedure;
end package body;
