-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2019, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

use work.integer_vector_ptr_pkg.all;
use work.string_ptr_pkg.all;
use work.logger_pkg.all;

package memory_types_pkg is

  type endianness_arg_t is (little_endian,
                            big_endian,
                            default_endian);
  subtype endianness_t is endianness_arg_t range little_endian to big_endian;

  -- Memory model object
  type memory_t is record
    -- Private
    p_meta : integer_vector_ptr_t;
    p_default_endian : endianness_t;
    p_check_permissions : boolean;
    p_data : integer_vector_ptr_t;
    p_buffers : integer_vector_ptr_t;
    p_logger : logger_t;
  end record;
  constant null_memory : memory_t := (p_logger => null_logger,
                                      p_check_permissions => boolean'low,
                                      p_default_endian => endianness_t'low,
                                      others => null_ptr);

  subtype byte_t is integer range 0 to 255;
  type permissions_t is ( no_access,
                          write_only,
                          read_only,
                          read_and_write);
  type memory_data_t is record
    byte : byte_t;
    exp : byte_t;
    has_exp : boolean;
    perm : permissions_t;
  end record;

end package;
