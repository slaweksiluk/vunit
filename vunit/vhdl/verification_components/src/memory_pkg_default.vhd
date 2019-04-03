-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

-- Model of a memory address space - default instantiation

library ieee;
use ieee.std_logic_1164.all;

use work.integer_vector_ptr_pkg.all;
use work.string_ptr_pkg.all;
use work.logger_pkg.all;
use work.memory_types_pkg.all;

package memory_pkg_default is
  -- Perform write of one byte without running any address or data checks
  procedure write_byte_unchecked(memory : memory_t; address : natural; byte : byte_t);
  -- Perform read of one byte without running any address or data checks
  impure function read_byte_unchecked(memory : memory_t; address : natural) return byte_t;

  -- Instantiate defualt memory_pkg
  package memory_pkg_inst is new work.memory_pkg
  generic map (
    write_byte_unchecked => write_byte_unchecked,
    read_byte_unchecked => read_byte_unchecked
  );

end package;
package body memory_pkg_default is

  impure function decode(value : integer) return memory_data_t is
  begin
    return (byte => value mod 256,
            exp => (value/256) mod 256,
            has_exp => (value/256**2) mod 2 = 1,
            perm => permissions_t'val((value/(2*256**2)) mod 256));
  end;

  impure function encode(memory_data : memory_data_t) return integer is
    variable result : integer;
  begin
    result := (memory_data.byte +
               memory_data.exp*256 +
               permissions_t'pos(memory_data.perm)*(2*256**2));
    if memory_data.has_exp then
      result := result + 256**2;
    end if;
    return result;
  end;

  procedure write_byte_unchecked(memory : memory_t; address : natural; byte : byte_t) is
    variable old : memory_data_t;
  begin
    old := decode(get(memory.p_data, address));
    set(memory.p_data, address, encode((byte => byte, exp => old.exp, has_exp => old.has_exp, perm => old.perm)));
  end;

  impure function read_byte_unchecked(memory : memory_t; address : natural) return byte_t is
  begin
    return decode(get(memory.p_data, address)).byte;
  end;

end package body;
