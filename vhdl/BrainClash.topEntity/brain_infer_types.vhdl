library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package brain_infer_types is




  type Tuple2_0 is record
    Tuple2_0_sel0_std_logic_vector_0 : std_logic_vector(7 downto 0);
    Tuple2_0_sel1_std_logic_vector_1 : std_logic_vector(23 downto 0);
  end record;
  type Tuple2 is record
    Tuple2_sel0_std_logic_vector_0 : std_logic_vector(0 downto 0);
    Tuple2_sel1_std_logic_vector_1 : std_logic_vector(15 downto 0);
  end record;
  type array_of_signed_16 is array (integer range <>) of signed(15 downto 0);
  type array_of_array_of_3_signed_16 is array (integer range <>) of array_of_signed_16(0 to 2);
  type array_of_array_of_4_signed_16 is array (integer range <>) of array_of_signed_16(0 to 3);
  function toSLV (slv : in std_logic_vector) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return std_logic_vector;
  function toSLV (b : in boolean) return std_logic_vector;
  function fromSLV (sl : in std_logic_vector) return boolean;
  function tagToEnum (s : in signed) return boolean;
  function dataToTag (b : in boolean) return signed;
  function toSLV (sl : in std_logic) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return std_logic;
  function toSLV (s : in signed) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return signed;
  function toSLV (p : Tuple2_0) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2_0;
  function toSLV (p : Tuple2) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return Tuple2;
  function toSLV (value :  array_of_signed_16) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return array_of_signed_16;
  function toSLV (value :  array_of_array_of_3_signed_16) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return array_of_array_of_3_signed_16;
  function toSLV (value :  array_of_array_of_4_signed_16) return std_logic_vector;
  function fromSLV (slv : in std_logic_vector) return array_of_array_of_4_signed_16;
end;

package body brain_infer_types is
  function toSLV (slv : in std_logic_vector) return std_logic_vector is
  begin
    return slv;
  end;
  function fromSLV (slv : in std_logic_vector) return std_logic_vector is
  begin
    return slv;
  end;
  function toSLV (b : in boolean) return std_logic_vector is
  begin
    if b then
      return "1";
    else
      return "0";
    end if;
  end;
  function fromSLV (sl : in std_logic_vector) return boolean is
  begin
    if sl = "1" then
      return true;
    else
      return false;
    end if;
  end;
  function tagToEnum (s : in signed) return boolean is
  begin
    if s = to_signed(0,64) then
      return false;
    else
      return true;
    end if;
  end;
  function dataToTag (b : in boolean) return signed is
  begin
    if b then
      return to_signed(1,64);
    else
      return to_signed(0,64);
    end if;
  end;
  function toSLV (sl : in std_logic) return std_logic_vector is
  begin
    return std_logic_vector'(0 => sl);
  end;
  function fromSLV (slv : in std_logic_vector) return std_logic is
    alias islv : std_logic_vector (0 to slv'length - 1) is slv;
  begin
    return islv(0);
  end;
  function toSLV (s : in signed) return std_logic_vector is
  begin
    return std_logic_vector(s);
  end;
  function fromSLV (slv : in std_logic_vector) return signed is
    alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return signed(islv);
  end;
  function toSLV (p : Tuple2_0) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_0_sel0_std_logic_vector_0) & toSLV(p.Tuple2_0_sel1_std_logic_vector_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2_0 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 7)),fromSLV(islv(8 to 31)));
  end;
  function toSLV (p : Tuple2) return std_logic_vector is
  begin
    return (toSLV(p.Tuple2_sel0_std_logic_vector_0) & toSLV(p.Tuple2_sel1_std_logic_vector_1));
  end;
  function fromSLV (slv : in std_logic_vector) return Tuple2 is
  alias islv : std_logic_vector(0 to slv'length - 1) is slv;
  begin
    return (fromSLV(islv(0 to 0)),fromSLV(islv(1 to 16)));
  end;
  function toSLV (value :  array_of_signed_16) return std_logic_vector is
    alias ivalue    : array_of_signed_16(1 to value'length) is value;
    variable result : std_logic_vector(1 to value'length * 16);
  begin
    for i in ivalue'range loop
      result(((i - 1) * 16) + 1 to i*16) := toSLV(ivalue(i));
    end loop;
    return result;
  end;
  function fromSLV (slv : in std_logic_vector) return array_of_signed_16 is
    alias islv      : std_logic_vector(0 to slv'length - 1) is slv;
    variable result : array_of_signed_16(0 to slv'length / 16 - 1);
  begin
    for i in result'range loop
      result(i) := fromSLV(islv(i * 16 to (i+1) * 16 - 1));
    end loop;
    return result;
  end;
  function toSLV (value :  array_of_array_of_3_signed_16) return std_logic_vector is
    alias ivalue    : array_of_array_of_3_signed_16(1 to value'length) is value;
    variable result : std_logic_vector(1 to value'length * 48);
  begin
    for i in ivalue'range loop
      result(((i - 1) * 48) + 1 to i*48) := toSLV(ivalue(i));
    end loop;
    return result;
  end;
  function fromSLV (slv : in std_logic_vector) return array_of_array_of_3_signed_16 is
    alias islv      : std_logic_vector(0 to slv'length - 1) is slv;
    variable result : array_of_array_of_3_signed_16(0 to slv'length / 48 - 1);
  begin
    for i in result'range loop
      result(i) := fromSLV(islv(i * 48 to (i+1) * 48 - 1));
    end loop;
    return result;
  end;
  function toSLV (value :  array_of_array_of_4_signed_16) return std_logic_vector is
    alias ivalue    : array_of_array_of_4_signed_16(1 to value'length) is value;
    variable result : std_logic_vector(1 to value'length * 64);
  begin
    for i in ivalue'range loop
      result(((i - 1) * 64) + 1 to i*64) := toSLV(ivalue(i));
    end loop;
    return result;
  end;
  function fromSLV (slv : in std_logic_vector) return array_of_array_of_4_signed_16 is
    alias islv      : std_logic_vector(0 to slv'length - 1) is slv;
    variable result : array_of_array_of_4_signed_16(0 to slv'length / 64 - 1);
  begin
    for i in result'range loop
      result(i) := fromSLV(islv(i * 64 to (i+1) * 64 - 1));
    end loop;
    return result;
  end;
end;

