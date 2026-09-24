-- Automatically generated VHDL-93
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use std.textio.all;
use work.all;
use work.switch_led_types.all;

entity switch_led is
  port(-- clock
       CLOCK_50 : in switch_led_types.clk_Board50;
       -- reset
       RESET    : in switch_led_types.rst_Board50;
       SW       : in std_logic_vector(3 downto 0);
       LED      : out std_logic_vector(7 downto 0));
end;

architecture structural of switch_led is
  signal \c$ds_app_arg\              : switch_led_types.Tuple3 := ( Tuple3_sel0_std_logic_vector_0 => std_logic_vector'(x"0")
, Tuple3_sel1_index_500000 => to_unsigned(0,19)
, Tuple3_sel2_std_logic_vector_1 => std_logic_vector'(x"0") );
  signal \c$ds_app_arg_0\            : std_logic_vector(3 downto 0) := std_logic_vector'(x"0");
  signal \c$ds_app_arg_1\            : std_logic_vector(3 downto 0) := std_logic_vector'(x"0");
  signal \c$app_arg\                 : switch_led_types.array_of_signed_16(0 to 1);
  signal \c$app_arg_0\               : switch_led_types.array_of_signed_16(0 to 1);
  signal result_0                    : switch_led_types.array_of_signed_16(0 to 1);
  signal \c$app_arg_1\               : std_logic_vector(7 downto 0);
  signal \c$app_arg_2\               : signed(15 downto 0);
  signal \c$app_arg_3\               : std_logic_vector(7 downto 0);
  signal \c$app_arg_4\               : signed(15 downto 0);
  signal \c$app_arg_5\               : switch_led_types.array_of_signed_16(0 to 2);
  signal \c$app_arg_6\               : switch_led_types.array_of_signed_16(0 to 2);
  signal result_1                    : switch_led_types.array_of_signed_16(0 to 2);
  signal \c$outputs_app_arg\         : switch_led_types.array_of_signed_16(0 to 3);
  signal nextAccepted                : std_logic_vector(3 downto 0);
  signal accepted                    : std_logic_vector(3 downto 0);
  signal \c$app_arg_7\               : switch_led_types.index_500000;
  signal \c$case_alt\                : switch_led_types.index_500000;
  signal same                        : boolean;
  signal candidate                   : std_logic_vector(3 downto 0);
  signal \c$nextAccepted_app_arg\    : boolean;
  signal count                       : switch_led_types.index_500000;
  signal result                      : std_logic_vector(7 downto 0) := std_logic_vector'(x"00");
  signal \c$vec1\                    : switch_led_types.array_of_signed_16(0 to 1);
  signal \c$vec\                     : switch_led_types.array_of_array_of_3_signed_16(0 to 1);
  signal \c$app_arg_selection_res\   : boolean;
  signal \c$app_arg_selection_res_0\ : boolean;
  signal \c$vec1_0\                  : switch_led_types.array_of_signed_16(0 to 2);
  signal \c$vec_0\                   : switch_led_types.array_of_array_of_4_signed_16(0 to 2);
  signal \c$vec_1\                   : switch_led_types.array_of_signed_64(0 to 3);
  signal nextAccepted_selection_res  : boolean;
  signal \c$app_arg_selection_res_1\ : boolean;

begin
  -- register begin
  cds_app_arg_register : process(CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      if RESET =  '1'  then
        \c$ds_app_arg\ <= ( Tuple3_sel0_std_logic_vector_0 => std_logic_vector'(x"0")
  , Tuple3_sel1_index_500000 => to_unsigned(0,19)
  , Tuple3_sel2_std_logic_vector_1 => std_logic_vector'(x"0") );
      else
        \c$ds_app_arg\ <= ( Tuple3_sel0_std_logic_vector_0 => \c$ds_app_arg_1\
  , Tuple3_sel1_index_500000 => \c$app_arg_7\
  , Tuple3_sel2_std_logic_vector_1 => nextAccepted );
      end if;
    end if;
  end process;
  -- register end

  -- register begin
  cds_app_arg_0_register : process(CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      if RESET =  '1'  then
        \c$ds_app_arg_0\ <= std_logic_vector'(x"0");
      else
        \c$ds_app_arg_0\ <= SW;
      end if;
    end if;
  end process;
  -- register end

  -- register begin
  cds_app_arg_1_register : process(CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      if RESET =  '1'  then
        \c$ds_app_arg_1\ <= std_logic_vector'(x"0");
      else
        \c$ds_app_arg_1\ <= \c$ds_app_arg_0\;
      end if;
    end if;
  end process;
  -- register end

  \c$vec1\ <= switch_led_types.array_of_signed_16'( to_signed(256,16)
                                                  , to_signed(255,16) );

  -- zipWith begin
  zipWith : for i in \c$app_arg\'range generate
  begin
    fun_11 : block
      signal result_2                   : signed(15 downto 0);
      signal \c$case_alt_0\             : signed(15 downto 0);
      signal \r'\                       : std_logic_vector(15 downto 0);
      signal \c$r'_app_arg\             : std_logic_vector(16 downto 0);
      signal r                          : signed(16 downto 0);
      signal result_selection_res       : boolean;
      signal \c$bv\                     : std_logic_vector(15 downto 0);
      signal \c$case_alt_selection_res\ : boolean;
      signal \c$bv_0\                   : std_logic_vector(15 downto 0);
      signal \c$bv_1\                   : std_logic_vector(15 downto 0);
      signal \r'_projection\            : switch_led_types.Tuple2;
    begin
      \c$app_arg\(i) <= result_2;

      \c$bv\ <= (\r'\);

      result_selection_res <= (( \c$r'_app_arg\(\c$r'_app_arg\'high) ) xor ( \c$bv\(\c$bv\'high) )) = '0';

      result_2 <= signed(\r'\) when result_selection_res else
                  \c$case_alt_0\;

      \c$bv_0\ <= ((std_logic_vector(\c$vec1\(i))));

      \c$bv_1\ <= ((std_logic_vector(\c$app_arg_0\(i))));

      \c$case_alt_selection_res\ <= (( \c$bv_0\(\c$bv_0\'high) ) and ( \c$bv_1\(\c$bv_1\'high) )) = '0';

      \c$case_alt_0\ <= to_signed(32767,16) when \c$case_alt_selection_res\ else
                        to_signed(-32768,16);

      \r'_projection\ <= (\c$r'_app_arg\(\c$r'_app_arg\'high downto 16),\c$r'_app_arg\(16-1 downto 0));

      \r'\ <= \r'_projection\.Tuple2_sel1_std_logic_vector_1;

      \c$r'_app_arg\ <= (std_logic_vector(r));

      r <= resize(\c$vec1\(i),17) + resize(\c$app_arg_0\(i),17);


    end block;
  end generate;
  -- zipWith end

  \c$vec\ <= switch_led_types.array_of_array_of_3_signed_16'( switch_led_types.array_of_signed_16'( to_signed(0,16)
                                                                                                  , to_signed(-309,16)
                                                                                                  , to_signed(0,16) )
                                                            , switch_led_types.array_of_signed_16'( to_signed(1,16)
                                                                                                  , to_signed(0,16)
                                                                                                  , to_signed(-322,16) ) );

  -- map begin
  r_map : for i_1 in \c$app_arg_0\'range generate
  begin
    fun_12 : block
      signal wild     : switch_led_types.array_of_signed_16(0 to 2);
      signal result_3 : signed(15 downto 0);
    begin
      \c$app_arg_0\(i_1) <= result_3;

      -- zipWith begin
      zipWith_0 : for i_0 in wild'range generate
      begin
        fun_13 : block
          signal result_4                     : signed(15 downto 0);
          signal \c$case_alt_1\               : signed(15 downto 0);
          signal \c$app_arg_8\                : std_logic_vector(23 downto 0);
          signal \c$app_arg_9\                : std_logic;
          signal \c$app_arg_10\               : std_logic;
          signal \c$app_arg_11\               : std_logic_vector(8 downto 0);
          signal \c$app_arg_12\               : std_logic_vector(7 downto 0);
          signal rL                           : std_logic_vector(7 downto 0);
          signal rR                           : std_logic_vector(23 downto 0);
          signal ds3                          : switch_led_types.Tuple2_0;
          signal result_selection_res_0       : boolean;
          signal \c$case_alt_selection_res_0\ : boolean;
          signal \c$shI\                      : signed(63 downto 0);
          signal \c$bv_2\                     : std_logic_vector(23 downto 0);
          signal \c$bv_3\                     : std_logic_vector(31 downto 0);
        begin
          wild(i_0) <= result_4;

          result_selection_res_0 <= ((not \c$app_arg_10\) or \c$app_arg_9\) = '1';

          result_4 <= signed((std_logic_vector(resize(unsigned(\c$app_arg_8\),16)))) when result_selection_res_0 else
                      \c$case_alt_1\;

          \c$case_alt_selection_res_0\ <= ( \c$app_arg_12\(\c$app_arg_12\'high) ) = '0';

          \c$case_alt_1\ <= to_signed(32767,16) when \c$case_alt_selection_res_0\ else
                            to_signed(-32768,16);

          \c$shI\ <= (to_signed(8,64));

          capp_arg_8_shiftR : block
            signal sh : natural;
          begin
            sh <=
                -- pragma translate_off
                natural'high when (\c$shI\(64-1 downto 31) /= 0) else
                -- pragma translate_on
                to_integer(\c$shI\);
            \c$app_arg_8\ <= std_logic_vector(shift_right(unsigned(rR),sh))
                -- pragma translate_off
                when ((to_signed(8,64)) >= 0) else (others => 'X')
                -- pragma translate_on
                ;
          end block;

          -- reduceAnd begin

          reduceAnd : block
            function and_reduce (arg : std_logic_vector) return std_logic is
              variable upper, lower : std_logic;
              variable half         : integer;
              variable argi         : std_logic_vector (arg'length - 1 downto 0);
              variable result_5       : std_logic;
            begin
              if (arg'length < 1) then
                result_5 := '1';
              else
                argi := arg;
                if (argi'length = 1) then
                  result_5 := argi(argi'left);
                else
                  half   := (argi'length + 1) / 2; -- lsb-biased tree
                  upper  := and_reduce (argi (argi'left downto half));
                  lower  := and_reduce (argi (half - 1 downto argi'right));
                  result_5 := upper and lower;
                end if;
              end if;
              return result_5;
            end;
          begin
            \c$app_arg_9\ <= and_reduce(\c$app_arg_11\);
          end block;
          -- reduceAnd end

          -- reduceOr begin
          reduceOr : block
            function or_reduce (arg_0 : std_logic_vector) return std_logic is
              variable upper_0, lower_0 : std_logic;
              variable half_0         : integer;
              variable argi_0         : std_logic_vector (arg_0'length - 1 downto 0);
              variable result_6       : std_logic;
            begin
              if (arg_0'length < 1) then
                result_6 := '0';
              else
                argi_0 := arg_0;
                if (argi_0'length = 1) then
                  result_6 := argi_0(argi_0'left);
                else
                  half_0   := (argi_0'length + 1) / 2; -- lsb-biased tree
                  upper_0  := or_reduce (argi_0 (argi_0'left downto half_0));
                  lower_0  := or_reduce (argi_0 (half_0 - 1 downto argi_0'right));
                  result_6 := upper_0 or lower_0;
                end if;
              end if;
              return result_6;
            end;
          begin
            \c$app_arg_10\ <= or_reduce(\c$app_arg_11\);
          end block;
          -- reduceOr end

          \c$bv_2\ <= (rR);

          \c$app_arg_11\ <= (std_logic_vector'(std_logic_vector'(((std_logic_vector'(0 => ( \c$bv_2\(\c$bv_2\'high) ))))) & std_logic_vector'(\c$app_arg_12\)));

          \c$app_arg_12\ <= rL;

          rL <= ds3.Tuple2_0_sel0_std_logic_vector_0;

          rR <= ds3.Tuple2_0_sel1_std_logic_vector_1;

          \c$bv_3\ <= ((std_logic_vector((result_1(i_0) * \c$vec\(i_1)(i_0)))));

          ds3 <= (\c$bv_3\(\c$bv_3\'high downto 24),\c$bv_3\(24-1 downto 0));


        end block;
      end generate;
      -- zipWith end

      fold : block
        signal vec     : switch_led_types.array_of_signed_16(0 to 2);
        signal acc_2_0 : signed(15 downto 0);
        signal acc_1   : signed(15 downto 0);
        signal acc_2   : signed(15 downto 0);
        signal acc_1_0 : signed(15 downto 0);
        signal acc_3   : signed(15 downto 0);
      begin
        result_3 <= acc_2_0;

        vec <= wild;

        acc_1 <= vec(0);

        acc_2 <= vec(1);

        acc_3 <= vec(2);

        fun_14 : block
            signal result_7                     : signed(15 downto 0);
            signal \c$case_alt_2\               : signed(15 downto 0);
            signal \r'_1\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_0\             : std_logic_vector(16 downto 0);
            signal r_0                          : signed(16 downto 0);
            signal result_selection_res_1       : boolean;
            signal \c$bv_4\                     : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_1\ : boolean;
            signal \c$bv_5\                     : std_logic_vector(15 downto 0);
            signal \c$bv_6\                     : std_logic_vector(15 downto 0);
            signal \r'_projection_0\            : switch_led_types.Tuple2;
          begin
            acc_1_0 <= result_7;

            \c$bv_4\ <= (\r'_1\);

            result_selection_res_1 <= (( \c$r'_app_arg_0\(\c$r'_app_arg_0\'high) ) xor ( \c$bv_4\(\c$bv_4\'high) )) = '0';

            result_7 <= signed(\r'_1\) when result_selection_res_1 else
                        \c$case_alt_2\;

            \c$bv_5\ <= ((std_logic_vector(acc_1)));

            \c$bv_6\ <= ((std_logic_vector(acc_2)));

            \c$case_alt_selection_res_1\ <= (( \c$bv_5\(\c$bv_5\'high) ) and ( \c$bv_6\(\c$bv_6\'high) )) = '0';

            \c$case_alt_2\ <= to_signed(32767,16) when \c$case_alt_selection_res_1\ else
                              to_signed(-32768,16);

            \r'_projection_0\ <= (\c$r'_app_arg_0\(\c$r'_app_arg_0\'high downto 16),\c$r'_app_arg_0\(16-1 downto 0));

            \r'_1\ <= \r'_projection_0\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_0\ <= (std_logic_vector(r_0));

            r_0 <= resize(acc_1,17) + resize(acc_2,17);


          end block;

        fun_15 : block
            signal result_8                     : signed(15 downto 0);
            signal \c$case_alt_3\               : signed(15 downto 0);
            signal \r'_2\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_1\             : std_logic_vector(16 downto 0);
            signal r_1                          : signed(16 downto 0);
            signal result_selection_res_2       : boolean;
            signal \c$bv_7\                     : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_2\ : boolean;
            signal \c$bv_8\                     : std_logic_vector(15 downto 0);
            signal \c$bv_9\                     : std_logic_vector(15 downto 0);
            signal \r'_projection_1\            : switch_led_types.Tuple2;
          begin
            acc_2_0 <= result_8;

            \c$bv_7\ <= (\r'_2\);

            result_selection_res_2 <= (( \c$r'_app_arg_1\(\c$r'_app_arg_1\'high) ) xor ( \c$bv_7\(\c$bv_7\'high) )) = '0';

            result_8 <= signed(\r'_2\) when result_selection_res_2 else
                        \c$case_alt_3\;

            \c$bv_8\ <= ((std_logic_vector(acc_1_0)));

            \c$bv_9\ <= ((std_logic_vector(acc_3)));

            \c$case_alt_selection_res_2\ <= (( \c$bv_8\(\c$bv_8\'high) ) and ( \c$bv_9\(\c$bv_9\'high) )) = '0';

            \c$case_alt_3\ <= to_signed(32767,16) when \c$case_alt_selection_res_2\ else
                              to_signed(-32768,16);

            \r'_projection_1\ <= (\c$r'_app_arg_1\(\c$r'_app_arg_1\'high downto 16),\c$r'_app_arg_1\(16-1 downto 0));

            \r'_2\ <= \r'_projection_1\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_1\ <= (std_logic_vector(r_1));

            r_1 <= resize(acc_1_0,17) + resize(acc_3,17);


          end block;


      end block;


    end block;
  end generate;
  -- map end

  -- map begin
  r_map_0 : for i_2 in result_0'range generate
  begin
    selection_1 : block
      signal result_9               : signed(15 downto 0);
      signal result_selection_res_3 : boolean;
    begin
      result_0(i_2) <= result_9;

      result_selection_res_3 <= to_signed(0,16) <= \c$app_arg\(i_2);

      result_9 <= \c$app_arg\(i_2) when result_selection_res_3 else
                  to_signed(0,16);


    end block;
  end generate;
  -- map end

  \c$app_arg_selection_res\ <= \c$app_arg_2\ >= to_signed(128,16);

  \c$app_arg_1\ <= std_logic_vector'(x"02") when \c$app_arg_selection_res\ else
                   std_logic_vector'(x"00");

  -- index begin
  indexVec : block
    signal vec_index : integer range 0 to 2-1;
  begin
    vec_index <= to_integer(to_signed(1,64))
    -- pragma translate_off
                 mod 2
    -- pragma translate_on
                 ;
    \c$app_arg_2\ <= result_0(vec_index);
  end block;
  -- index end

  \c$app_arg_selection_res_0\ <= \c$app_arg_4\ >= to_signed(128,16);

  \c$app_arg_3\ <= std_logic_vector'(x"01") when \c$app_arg_selection_res_0\ else
                   std_logic_vector'(x"00");

  -- index begin
  indexVec_0 : block
    signal vec_index_0 : integer range 0 to 2-1;
  begin
    vec_index_0 <= to_integer(to_signed(0,64))
    -- pragma translate_off
                 mod 2
    -- pragma translate_on
                 ;
    \c$app_arg_4\ <= result_0(vec_index_0);
  end block;
  -- index end

  \c$vec1_0\ <= switch_led_types.array_of_signed_16'( to_signed(147,16)
                                                    , to_signed(212,16)
                                                    , to_signed(203,16) );

  -- zipWith begin
  zipWith_1 : for i_3 in \c$app_arg_5\'range generate
  begin
    fun_16 : block
      signal result_10                    : signed(15 downto 0);
      signal \c$case_alt_4\               : signed(15 downto 0);
      signal \r'_3\                       : std_logic_vector(15 downto 0);
      signal \c$r'_app_arg_2\             : std_logic_vector(16 downto 0);
      signal r_2                          : signed(16 downto 0);
      signal result_selection_res_4       : boolean;
      signal \c$bv_10\                    : std_logic_vector(15 downto 0);
      signal \c$case_alt_selection_res_3\ : boolean;
      signal \c$bv_11\                    : std_logic_vector(15 downto 0);
      signal \c$bv_12\                    : std_logic_vector(15 downto 0);
      signal \r'_projection_2\            : switch_led_types.Tuple2;
    begin
      \c$app_arg_5\(i_3) <= result_10;

      \c$bv_10\ <= (\r'_3\);

      result_selection_res_4 <= (( \c$r'_app_arg_2\(\c$r'_app_arg_2\'high) ) xor ( \c$bv_10\(\c$bv_10\'high) )) = '0';

      result_10 <= signed(\r'_3\) when result_selection_res_4 else
                   \c$case_alt_4\;

      \c$bv_11\ <= ((std_logic_vector(\c$vec1_0\(i_3))));

      \c$bv_12\ <= ((std_logic_vector(\c$app_arg_6\(i_3))));

      \c$case_alt_selection_res_3\ <= (( \c$bv_11\(\c$bv_11\'high) ) and ( \c$bv_12\(\c$bv_12\'high) )) = '0';

      \c$case_alt_4\ <= to_signed(32767,16) when \c$case_alt_selection_res_3\ else
                        to_signed(-32768,16);

      \r'_projection_2\ <= (\c$r'_app_arg_2\(\c$r'_app_arg_2\'high downto 16),\c$r'_app_arg_2\(16-1 downto 0));

      \r'_3\ <= \r'_projection_2\.Tuple2_sel1_std_logic_vector_1;

      \c$r'_app_arg_2\ <= (std_logic_vector(r_2));

      r_2 <= resize(\c$vec1_0\(i_3),17) + resize(\c$app_arg_6\(i_3),17);


    end block;
  end generate;
  -- zipWith end

  \c$vec_0\ <= switch_led_types.array_of_array_of_4_signed_16'( switch_led_types.array_of_signed_16'( to_signed(97,16)
                                                                                                    , to_signed(54,16)
                                                                                                    , to_signed(78,16)
                                                                                                    , to_signed(20,16) )
                                                              , switch_led_types.array_of_signed_16'( to_signed(-212,16)
                                                                                                    , to_signed(0,16)
                                                                                                    , to_signed(-212,16)
                                                                                                    , to_signed(0,16) )
                                                              , switch_led_types.array_of_signed_16'( to_signed(9,16)
                                                                                                    , to_signed(-215,16)
                                                                                                    , to_signed(2,16)
                                                                                                    , to_signed(-215,16) ) );

  -- map begin
  r_map_1 : for i_5 in \c$app_arg_6\'range generate
  begin
    fun_17 : block
      signal wild_0    : switch_led_types.array_of_signed_16(0 to 3);
      signal result_11 : signed(15 downto 0);
    begin
      \c$app_arg_6\(i_5) <= result_11;

      -- zipWith begin
      zipWith_2 : for i_4 in wild_0'range generate
      begin
        fun_18 : block
          signal result_12                    : signed(15 downto 0);
          signal \c$case_alt_5\               : signed(15 downto 0);
          signal \c$app_arg_13\               : std_logic_vector(23 downto 0);
          signal \c$app_arg_14\               : std_logic;
          signal \c$app_arg_15\               : std_logic;
          signal \c$app_arg_16\               : std_logic_vector(8 downto 0);
          signal \c$app_arg_17\               : std_logic_vector(7 downto 0);
          signal rL_1                         : std_logic_vector(7 downto 0);
          signal rR_1                         : std_logic_vector(23 downto 0);
          signal ds3_0                        : switch_led_types.Tuple2_0;
          signal result_selection_res_5       : boolean;
          signal \c$case_alt_selection_res_4\ : boolean;
          signal \c$shI_0\                    : signed(63 downto 0);
          signal \c$bv_13\                    : std_logic_vector(23 downto 0);
          signal \c$bv_14\                    : std_logic_vector(31 downto 0);
        begin
          wild_0(i_4) <= result_12;

          result_selection_res_5 <= ((not \c$app_arg_15\) or \c$app_arg_14\) = '1';

          result_12 <= signed((std_logic_vector(resize(unsigned(\c$app_arg_13\),16)))) when result_selection_res_5 else
                       \c$case_alt_5\;

          \c$case_alt_selection_res_4\ <= ( \c$app_arg_17\(\c$app_arg_17\'high) ) = '0';

          \c$case_alt_5\ <= to_signed(32767,16) when \c$case_alt_selection_res_4\ else
                            to_signed(-32768,16);

          \c$shI_0\ <= (to_signed(8,64));

          capp_arg_13_shiftR : block
            signal sh_0 : natural;
          begin
            sh_0 <=
                -- pragma translate_off
                natural'high when (\c$shI_0\(64-1 downto 31) /= 0) else
                -- pragma translate_on
                to_integer(\c$shI_0\);
            \c$app_arg_13\ <= std_logic_vector(shift_right(unsigned(rR_1),sh_0))
                -- pragma translate_off
                when ((to_signed(8,64)) >= 0) else (others => 'X')
                -- pragma translate_on
                ;
          end block;

          -- reduceAnd begin

          reduceAnd_0 : block
            function and_reduce_0 (arg_1 : std_logic_vector) return std_logic is
              variable upper_1, lower_1 : std_logic;
              variable half_1         : integer;
              variable argi_1         : std_logic_vector (arg_1'length - 1 downto 0);
              variable result_13       : std_logic;
            begin
              if (arg_1'length < 1) then
                result_13 := '1';
              else
                argi_1 := arg_1;
                if (argi_1'length = 1) then
                  result_13 := argi_1(argi_1'left);
                else
                  half_1   := (argi_1'length + 1) / 2; -- lsb-biased tree
                  upper_1  := and_reduce_0 (argi_1 (argi_1'left downto half_1));
                  lower_1  := and_reduce_0 (argi_1 (half_1 - 1 downto argi_1'right));
                  result_13 := upper_1 and lower_1;
                end if;
              end if;
              return result_13;
            end;
          begin
            \c$app_arg_14\ <= and_reduce_0(\c$app_arg_16\);
          end block;
          -- reduceAnd end

          -- reduceOr begin
          reduceOr_0 : block
            function or_reduce_0 (arg_2 : std_logic_vector) return std_logic is
              variable upper_2, lower_2 : std_logic;
              variable half_2         : integer;
              variable argi_2         : std_logic_vector (arg_2'length - 1 downto 0);
              variable result_14       : std_logic;
            begin
              if (arg_2'length < 1) then
                result_14 := '0';
              else
                argi_2 := arg_2;
                if (argi_2'length = 1) then
                  result_14 := argi_2(argi_2'left);
                else
                  half_2   := (argi_2'length + 1) / 2; -- lsb-biased tree
                  upper_2  := or_reduce_0 (argi_2 (argi_2'left downto half_2));
                  lower_2  := or_reduce_0 (argi_2 (half_2 - 1 downto argi_2'right));
                  result_14 := upper_2 or lower_2;
                end if;
              end if;
              return result_14;
            end;
          begin
            \c$app_arg_15\ <= or_reduce_0(\c$app_arg_16\);
          end block;
          -- reduceOr end

          \c$bv_13\ <= (rR_1);

          \c$app_arg_16\ <= (std_logic_vector'(std_logic_vector'(((std_logic_vector'(0 => ( \c$bv_13\(\c$bv_13\'high) ))))) & std_logic_vector'(\c$app_arg_17\)));

          \c$app_arg_17\ <= rL_1;

          rL_1 <= ds3_0.Tuple2_0_sel0_std_logic_vector_0;

          rR_1 <= ds3_0.Tuple2_0_sel1_std_logic_vector_1;

          \c$bv_14\ <= ((std_logic_vector((\c$outputs_app_arg\(i_4) * \c$vec_0\(i_5)(i_4)))));

          ds3_0 <= (\c$bv_14\(\c$bv_14\'high downto 24),\c$bv_14\(24-1 downto 0));


        end block;
      end generate;
      -- zipWith end

      fold_0 : block
        signal vec_0     : switch_led_types.array_of_signed_16(0 to 3);
        signal acc_2_0_1 : signed(15 downto 0);
        signal acc_0_2   : signed(15 downto 0);
        signal acc_0_3   : signed(15 downto 0);
        signal acc_0_4   : signed(15 downto 0);
        signal acc_0_5   : signed(15 downto 0);
        signal acc_1_0_0 : signed(15 downto 0);
        signal acc_1_1   : signed(15 downto 0);
      begin
        result_11 <= acc_2_0_1;

        vec_0 <= wild_0;

        acc_0_2 <= vec_0(0);

        acc_0_3 <= vec_0(1);

        acc_0_4 <= vec_0(2);

        acc_0_5 <= vec_0(3);

        fun_19 : block
            signal result_15                    : signed(15 downto 0);
            signal \c$case_alt_6\               : signed(15 downto 0);
            signal \r'_4\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_3\             : std_logic_vector(16 downto 0);
            signal r_3                          : signed(16 downto 0);
            signal result_selection_res_6       : boolean;
            signal \c$bv_15\                    : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_5\ : boolean;
            signal \c$bv_16\                    : std_logic_vector(15 downto 0);
            signal \c$bv_17\                    : std_logic_vector(15 downto 0);
            signal \r'_projection_3\            : switch_led_types.Tuple2;
          begin
            acc_1_0_0 <= result_15;

            \c$bv_15\ <= (\r'_4\);

            result_selection_res_6 <= (( \c$r'_app_arg_3\(\c$r'_app_arg_3\'high) ) xor ( \c$bv_15\(\c$bv_15\'high) )) = '0';

            result_15 <= signed(\r'_4\) when result_selection_res_6 else
                         \c$case_alt_6\;

            \c$bv_16\ <= ((std_logic_vector(acc_0_2)));

            \c$bv_17\ <= ((std_logic_vector(acc_0_3)));

            \c$case_alt_selection_res_5\ <= (( \c$bv_16\(\c$bv_16\'high) ) and ( \c$bv_17\(\c$bv_17\'high) )) = '0';

            \c$case_alt_6\ <= to_signed(32767,16) when \c$case_alt_selection_res_5\ else
                              to_signed(-32768,16);

            \r'_projection_3\ <= (\c$r'_app_arg_3\(\c$r'_app_arg_3\'high downto 16),\c$r'_app_arg_3\(16-1 downto 0));

            \r'_4\ <= \r'_projection_3\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_3\ <= (std_logic_vector(r_3));

            r_3 <= resize(acc_0_2,17) + resize(acc_0_3,17);


          end block;

        fun_20 : block
            signal result_16                    : signed(15 downto 0);
            signal \c$case_alt_7\               : signed(15 downto 0);
            signal \r'_5\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_4\             : std_logic_vector(16 downto 0);
            signal r_4                          : signed(16 downto 0);
            signal result_selection_res_7       : boolean;
            signal \c$bv_18\                    : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_6\ : boolean;
            signal \c$bv_19\                    : std_logic_vector(15 downto 0);
            signal \c$bv_20\                    : std_logic_vector(15 downto 0);
            signal \r'_projection_4\            : switch_led_types.Tuple2;
          begin
            acc_1_1 <= result_16;

            \c$bv_18\ <= (\r'_5\);

            result_selection_res_7 <= (( \c$r'_app_arg_4\(\c$r'_app_arg_4\'high) ) xor ( \c$bv_18\(\c$bv_18\'high) )) = '0';

            result_16 <= signed(\r'_5\) when result_selection_res_7 else
                         \c$case_alt_7\;

            \c$bv_19\ <= ((std_logic_vector(acc_0_4)));

            \c$bv_20\ <= ((std_logic_vector(acc_0_5)));

            \c$case_alt_selection_res_6\ <= (( \c$bv_19\(\c$bv_19\'high) ) and ( \c$bv_20\(\c$bv_20\'high) )) = '0';

            \c$case_alt_7\ <= to_signed(32767,16) when \c$case_alt_selection_res_6\ else
                              to_signed(-32768,16);

            \r'_projection_4\ <= (\c$r'_app_arg_4\(\c$r'_app_arg_4\'high downto 16),\c$r'_app_arg_4\(16-1 downto 0));

            \r'_5\ <= \r'_projection_4\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_4\ <= (std_logic_vector(r_4));

            r_4 <= resize(acc_0_4,17) + resize(acc_0_5,17);


          end block;

        fun_21 : block
            signal result_17                    : signed(15 downto 0);
            signal \c$case_alt_8\               : signed(15 downto 0);
            signal \r'_6\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_5\             : std_logic_vector(16 downto 0);
            signal r_5                          : signed(16 downto 0);
            signal result_selection_res_8       : boolean;
            signal \c$bv_21\                    : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_7\ : boolean;
            signal \c$bv_22\                    : std_logic_vector(15 downto 0);
            signal \c$bv_23\                    : std_logic_vector(15 downto 0);
            signal \r'_projection_5\            : switch_led_types.Tuple2;
          begin
            acc_2_0_1 <= result_17;

            \c$bv_21\ <= (\r'_6\);

            result_selection_res_8 <= (( \c$r'_app_arg_5\(\c$r'_app_arg_5\'high) ) xor ( \c$bv_21\(\c$bv_21\'high) )) = '0';

            result_17 <= signed(\r'_6\) when result_selection_res_8 else
                         \c$case_alt_8\;

            \c$bv_22\ <= ((std_logic_vector(acc_1_0_0)));

            \c$bv_23\ <= ((std_logic_vector(acc_1_1)));

            \c$case_alt_selection_res_7\ <= (( \c$bv_22\(\c$bv_22\'high) ) and ( \c$bv_23\(\c$bv_23\'high) )) = '0';

            \c$case_alt_8\ <= to_signed(32767,16) when \c$case_alt_selection_res_7\ else
                              to_signed(-32768,16);

            \r'_projection_5\ <= (\c$r'_app_arg_5\(\c$r'_app_arg_5\'high downto 16),\c$r'_app_arg_5\(16-1 downto 0));

            \r'_6\ <= \r'_projection_5\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_5\ <= (std_logic_vector(r_5));

            r_5 <= resize(acc_1_0_0,17) + resize(acc_1_1,17);


          end block;


      end block;


    end block;
  end generate;
  -- map end

  -- map begin
  r_map_2 : for i_6 in result_1'range generate
  begin
    selection_2 : block
      signal result_18              : signed(15 downto 0);
      signal result_selection_res_9 : boolean;
    begin
      result_1(i_6) <= result_18;

      result_selection_res_9 <= to_signed(0,16) <= \c$app_arg_5\(i_6);

      result_18 <= \c$app_arg_5\(i_6) when result_selection_res_9 else
                   to_signed(0,16);


    end block;
  end generate;
  -- map end

  \c$vec_1\ <= switch_led_types.array_of_signed_64'( to_signed(0,64)
                                                   , to_signed(1,64)
                                                   , to_signed(2,64)
                                                   , to_signed(3,64) );

  -- map begin
  r_map_3 : for i_7 in \c$outputs_app_arg\'range generate
  begin
    fun_22 : block
      signal \c$app_arg_18\          : std_logic;
      signal result_19               : signed(15 downto 0);
      signal result_selection_res_10 : boolean;
    begin
      \c$outputs_app_arg\(i_7) <= result_19;

      -- indexBitVector begin
      indexBitVector : block
        signal vec_index_1 : integer range 0 to 4-1;
      begin
        vec_index_1 <= to_integer(\c$vec_1\(i_7))
        -- pragma translate_off
                     mod 4
        -- pragma translate_on
                     ;

        \c$app_arg_18\ <= nextAccepted(vec_index_1);
      end block;
      -- indexBitVector end

      result_selection_res_10 <= \c$app_arg_18\ = ('1');

      result_19 <= to_signed(256,16) when result_selection_res_10 else
                   to_signed(0,16);


    end block;
  end generate;
  -- map end

  nextAccepted_selection_res <= same and \c$nextAccepted_app_arg\;

  nextAccepted <= \c$ds_app_arg_1\ when nextAccepted_selection_res else
                  accepted;

  accepted <= \c$ds_app_arg\.Tuple3_sel2_std_logic_vector_1;

  \c$app_arg_selection_res_1\ <= not same;

  \c$app_arg_7\ <= to_unsigned(1,19) when \c$app_arg_selection_res_1\ else
                   \c$case_alt\;

  \c$case_alt\ <= to_unsigned(499999,19) when \c$nextAccepted_app_arg\ else
                  count + to_unsigned(1,19);

  same <= \c$ds_app_arg_1\ = candidate;

  candidate <= \c$ds_app_arg\.Tuple3_sel0_std_logic_vector_0;

  \c$nextAccepted_app_arg\ <= count = to_unsigned(499999,19);

  count <= \c$ds_app_arg\.Tuple3_sel1_index_500000;

  -- register begin
  result_register : process(CLOCK_50)
  begin
    if rising_edge(CLOCK_50) then
      if RESET =  '1'  then
        result <= std_logic_vector'(x"00");
      else
        result <= (\c$app_arg_3\ or \c$app_arg_1\);
      end if;
    end if;
  end process;
  -- register end

  LED <= result;


end;

