-- Automatically generated VHDL-93
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use std.textio.all;
use work.all;
use work.brain_infer_types.all;

entity brain_infer is
  port(input  : in std_logic_vector(63 downto 0);
       output : out std_logic_vector(31 downto 0));
end;

architecture structural of brain_infer is
  signal \c$app_arg\   : brain_infer_types.array_of_signed_16(0 to 2);
  signal \c$app_arg_0\ : brain_infer_types.array_of_signed_16(0 to 2);
  signal result        : brain_infer_types.array_of_signed_16(0 to 2);
  signal \c$app_arg_1\ : brain_infer_types.array_of_signed_16(0 to 1);
  signal \c$app_arg_2\ : brain_infer_types.array_of_signed_16(0 to 1);
  signal \input_0\     : brain_infer_types.array_of_signed_16(0 to 3);
  signal \c$vec1\      : brain_infer_types.array_of_signed_16(0 to 2);
  signal \c$vec\       : brain_infer_types.array_of_array_of_4_signed_16(0 to 2);
  signal \c$vec1_0\    : brain_infer_types.array_of_signed_16(0 to 1);
  signal \c$vec_0\     : brain_infer_types.array_of_array_of_3_signed_16(0 to 1);
  signal \output_0\    : brain_infer_types.array_of_signed_16(0 to 1);

begin
  \input_0\ <= brain_infer_types.array_of_signed_16'(brain_infer_types.fromSLV(input));

  \c$vec1\ <= brain_infer_types.array_of_signed_16'( to_signed(258,16)
                                                   , to_signed(258,16)
                                                   , to_signed(258,16) );

  -- zipWith begin
  zipWith : for i in \c$app_arg\'range generate
  begin
    fun_10 : block
      signal result_0                   : signed(15 downto 0);
      signal \c$case_alt\               : signed(15 downto 0);
      signal \r'\                       : std_logic_vector(15 downto 0);
      signal \c$r'_app_arg\             : std_logic_vector(16 downto 0);
      signal r                          : signed(16 downto 0);
      signal result_selection_res       : boolean;
      signal \c$bv\                     : std_logic_vector(15 downto 0);
      signal \c$case_alt_selection_res\ : boolean;
      signal \c$bv_0\                   : std_logic_vector(15 downto 0);
      signal \c$bv_1\                   : std_logic_vector(15 downto 0);
      signal \r'_projection\            : brain_infer_types.Tuple2;
    begin
      \c$app_arg\(i) <= result_0;

      \c$bv\ <= (\r'\);

      result_selection_res <= (( \c$r'_app_arg\(\c$r'_app_arg\'high) ) xor ( \c$bv\(\c$bv\'high) )) = '0';

      result_0 <= signed(\r'\) when result_selection_res else
                  \c$case_alt\;

      \c$bv_0\ <= ((std_logic_vector(\c$vec1\(i))));

      \c$bv_1\ <= ((std_logic_vector(\c$app_arg_0\(i))));

      \c$case_alt_selection_res\ <= (( \c$bv_0\(\c$bv_0\'high) ) and ( \c$bv_1\(\c$bv_1\'high) )) = '0';

      \c$case_alt\ <= to_signed(32767,16) when \c$case_alt_selection_res\ else
                      to_signed(-32768,16);

      \r'_projection\ <= (\c$r'_app_arg\(\c$r'_app_arg\'high downto 16),\c$r'_app_arg\(16-1 downto 0));

      \r'\ <= \r'_projection\.Tuple2_sel1_std_logic_vector_1;

      \c$r'_app_arg\ <= (std_logic_vector(r));

      r <= resize(\c$vec1\(i),17) + resize(\c$app_arg_0\(i),17);


    end block;
  end generate;
  -- zipWith end

  \c$vec\ <= brain_infer_types.array_of_array_of_4_signed_16'( brain_infer_types.array_of_signed_16'( to_signed(2,16)
                                                                                                    , to_signed(2,16)
                                                                                                    , to_signed(10,16)
                                                                                                    , to_signed(2,16) )
                                                             , brain_infer_types.array_of_signed_16'( to_signed(2,16)
                                                                                                    , to_signed(5,16)
                                                                                                    , to_signed(6,16)
                                                                                                    , to_signed(7,16) )
                                                             , brain_infer_types.array_of_signed_16'( to_signed(0,16)
                                                                                                    , to_signed(2,16)
                                                                                                    , to_signed(6,16)
                                                                                                    , to_signed(10,16) ) );

  -- map begin
  r_map : for i_1 in \c$app_arg_0\'range generate
  begin
    fun_11 : block
      signal wild     : brain_infer_types.array_of_signed_16(0 to 3);
      signal result_1 : signed(15 downto 0);
    begin
      \c$app_arg_0\(i_1) <= result_1;

      -- zipWith begin
      zipWith_0 : for i_0 in wild'range generate
      begin
        fun_12 : block
          signal result_2                     : signed(15 downto 0);
          signal \c$case_alt_3\               : signed(15 downto 0);
          signal \c$app_arg_3\                : std_logic_vector(23 downto 0);
          signal \c$app_arg_4\                : std_logic;
          signal \c$app_arg_5\                : std_logic;
          signal \c$app_arg_6\                : std_logic_vector(8 downto 0);
          signal \c$app_arg_7\                : std_logic_vector(7 downto 0);
          signal rL                           : std_logic_vector(7 downto 0);
          signal rR                           : std_logic_vector(23 downto 0);
          signal ds3                          : brain_infer_types.Tuple2_0;
          signal result_selection_res_0       : boolean;
          signal \c$case_alt_selection_res_0\ : boolean;
          signal \c$shI\                      : signed(63 downto 0);
          signal \c$bv_2\                     : std_logic_vector(23 downto 0);
          signal \c$bv_3\                     : std_logic_vector(31 downto 0);
        begin
          wild(i_0) <= result_2;

          result_selection_res_0 <= ((not \c$app_arg_5\) or \c$app_arg_4\) = '1';

          result_2 <= signed((std_logic_vector(resize(unsigned(\c$app_arg_3\),16)))) when result_selection_res_0 else
                      \c$case_alt_3\;

          \c$case_alt_selection_res_0\ <= ( \c$app_arg_7\(\c$app_arg_7\'high) ) = '0';

          \c$case_alt_3\ <= to_signed(32767,16) when \c$case_alt_selection_res_0\ else
                            to_signed(-32768,16);

          \c$shI\ <= (to_signed(8,64));

          capp_arg_3_shiftR : block
            signal sh : natural;
          begin
            sh <=
                -- pragma translate_off
                natural'high when (\c$shI\(64-1 downto 31) /= 0) else
                -- pragma translate_on
                to_integer(\c$shI\);
            \c$app_arg_3\ <= std_logic_vector(shift_right(unsigned(rR),sh))
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
              variable result_3       : std_logic;
            begin
              if (arg'length < 1) then
                result_3 := '1';
              else
                argi := arg;
                if (argi'length = 1) then
                  result_3 := argi(argi'left);
                else
                  half   := (argi'length + 1) / 2; -- lsb-biased tree
                  upper  := and_reduce (argi (argi'left downto half));
                  lower  := and_reduce (argi (half - 1 downto argi'right));
                  result_3 := upper and lower;
                end if;
              end if;
              return result_3;
            end;
          begin
            \c$app_arg_4\ <= and_reduce(\c$app_arg_6\);
          end block;
          -- reduceAnd end

          -- reduceOr begin
          reduceOr : block
            function or_reduce (arg_0 : std_logic_vector) return std_logic is
              variable upper_0, lower_0 : std_logic;
              variable half_0         : integer;
              variable argi_0         : std_logic_vector (arg_0'length - 1 downto 0);
              variable result_4       : std_logic;
            begin
              if (arg_0'length < 1) then
                result_4 := '0';
              else
                argi_0 := arg_0;
                if (argi_0'length = 1) then
                  result_4 := argi_0(argi_0'left);
                else
                  half_0   := (argi_0'length + 1) / 2; -- lsb-biased tree
                  upper_0  := or_reduce (argi_0 (argi_0'left downto half_0));
                  lower_0  := or_reduce (argi_0 (half_0 - 1 downto argi_0'right));
                  result_4 := upper_0 or lower_0;
                end if;
              end if;
              return result_4;
            end;
          begin
            \c$app_arg_5\ <= or_reduce(\c$app_arg_6\);
          end block;
          -- reduceOr end

          \c$bv_2\ <= (rR);

          \c$app_arg_6\ <= (std_logic_vector'(std_logic_vector'(((std_logic_vector'(0 => ( \c$bv_2\(\c$bv_2\'high) ))))) & std_logic_vector'(\c$app_arg_7\)));

          \c$app_arg_7\ <= rL;

          rL <= ds3.Tuple2_0_sel0_std_logic_vector_0;

          rR <= ds3.Tuple2_0_sel1_std_logic_vector_1;

          \c$bv_3\ <= ((std_logic_vector((\input_0\(i_0) * \c$vec\(i_1)(i_0)))));

          ds3 <= (\c$bv_3\(\c$bv_3\'high downto 24),\c$bv_3\(24-1 downto 0));


        end block;
      end generate;
      -- zipWith end

      fold : block
        signal vec     : brain_infer_types.array_of_signed_16(0 to 3);
        signal acc_2_0 : signed(15 downto 0);
        signal acc_1   : signed(15 downto 0);
        signal acc_2   : signed(15 downto 0);
        signal acc_3   : signed(15 downto 0);
        signal acc_4   : signed(15 downto 0);
        signal acc_1_0 : signed(15 downto 0);
        signal acc_1_1 : signed(15 downto 0);
      begin
        result_1 <= acc_2_0;

        vec <= wild;

        acc_1 <= vec(0);

        acc_2 <= vec(1);

        acc_3 <= vec(2);

        acc_4 <= vec(3);

        fun_13 : block
            signal result_5                     : signed(15 downto 0);
            signal \c$case_alt_4\               : signed(15 downto 0);
            signal \r'_1\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_0\             : std_logic_vector(16 downto 0);
            signal r_0                          : signed(16 downto 0);
            signal result_selection_res_1       : boolean;
            signal \c$bv_4\                     : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_1\ : boolean;
            signal \c$bv_5\                     : std_logic_vector(15 downto 0);
            signal \c$bv_6\                     : std_logic_vector(15 downto 0);
            signal \r'_projection_0\            : brain_infer_types.Tuple2;
          begin
            acc_1_0 <= result_5;

            \c$bv_4\ <= (\r'_1\);

            result_selection_res_1 <= (( \c$r'_app_arg_0\(\c$r'_app_arg_0\'high) ) xor ( \c$bv_4\(\c$bv_4\'high) )) = '0';

            result_5 <= signed(\r'_1\) when result_selection_res_1 else
                        \c$case_alt_4\;

            \c$bv_5\ <= ((std_logic_vector(acc_1)));

            \c$bv_6\ <= ((std_logic_vector(acc_2)));

            \c$case_alt_selection_res_1\ <= (( \c$bv_5\(\c$bv_5\'high) ) and ( \c$bv_6\(\c$bv_6\'high) )) = '0';

            \c$case_alt_4\ <= to_signed(32767,16) when \c$case_alt_selection_res_1\ else
                              to_signed(-32768,16);

            \r'_projection_0\ <= (\c$r'_app_arg_0\(\c$r'_app_arg_0\'high downto 16),\c$r'_app_arg_0\(16-1 downto 0));

            \r'_1\ <= \r'_projection_0\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_0\ <= (std_logic_vector(r_0));

            r_0 <= resize(acc_1,17) + resize(acc_2,17);


          end block;

        fun_14 : block
            signal result_6                     : signed(15 downto 0);
            signal \c$case_alt_5\               : signed(15 downto 0);
            signal \r'_2\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_1\             : std_logic_vector(16 downto 0);
            signal r_1                          : signed(16 downto 0);
            signal result_selection_res_2       : boolean;
            signal \c$bv_7\                     : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_2\ : boolean;
            signal \c$bv_8\                     : std_logic_vector(15 downto 0);
            signal \c$bv_9\                     : std_logic_vector(15 downto 0);
            signal \r'_projection_1\            : brain_infer_types.Tuple2;
          begin
            acc_1_1 <= result_6;

            \c$bv_7\ <= (\r'_2\);

            result_selection_res_2 <= (( \c$r'_app_arg_1\(\c$r'_app_arg_1\'high) ) xor ( \c$bv_7\(\c$bv_7\'high) )) = '0';

            result_6 <= signed(\r'_2\) when result_selection_res_2 else
                        \c$case_alt_5\;

            \c$bv_8\ <= ((std_logic_vector(acc_3)));

            \c$bv_9\ <= ((std_logic_vector(acc_4)));

            \c$case_alt_selection_res_2\ <= (( \c$bv_8\(\c$bv_8\'high) ) and ( \c$bv_9\(\c$bv_9\'high) )) = '0';

            \c$case_alt_5\ <= to_signed(32767,16) when \c$case_alt_selection_res_2\ else
                              to_signed(-32768,16);

            \r'_projection_1\ <= (\c$r'_app_arg_1\(\c$r'_app_arg_1\'high downto 16),\c$r'_app_arg_1\(16-1 downto 0));

            \r'_2\ <= \r'_projection_1\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_1\ <= (std_logic_vector(r_1));

            r_1 <= resize(acc_3,17) + resize(acc_4,17);


          end block;

        fun_15 : block
            signal result_7                     : signed(15 downto 0);
            signal \c$case_alt_6\               : signed(15 downto 0);
            signal \r'_3\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_2\             : std_logic_vector(16 downto 0);
            signal r_2                          : signed(16 downto 0);
            signal result_selection_res_3       : boolean;
            signal \c$bv_10\                    : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_3\ : boolean;
            signal \c$bv_11\                    : std_logic_vector(15 downto 0);
            signal \c$bv_12\                    : std_logic_vector(15 downto 0);
            signal \r'_projection_2\            : brain_infer_types.Tuple2;
          begin
            acc_2_0 <= result_7;

            \c$bv_10\ <= (\r'_3\);

            result_selection_res_3 <= (( \c$r'_app_arg_2\(\c$r'_app_arg_2\'high) ) xor ( \c$bv_10\(\c$bv_10\'high) )) = '0';

            result_7 <= signed(\r'_3\) when result_selection_res_3 else
                        \c$case_alt_6\;

            \c$bv_11\ <= ((std_logic_vector(acc_1_0)));

            \c$bv_12\ <= ((std_logic_vector(acc_1_1)));

            \c$case_alt_selection_res_3\ <= (( \c$bv_11\(\c$bv_11\'high) ) and ( \c$bv_12\(\c$bv_12\'high) )) = '0';

            \c$case_alt_6\ <= to_signed(32767,16) when \c$case_alt_selection_res_3\ else
                              to_signed(-32768,16);

            \r'_projection_2\ <= (\c$r'_app_arg_2\(\c$r'_app_arg_2\'high downto 16),\c$r'_app_arg_2\(16-1 downto 0));

            \r'_3\ <= \r'_projection_2\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_2\ <= (std_logic_vector(r_2));

            r_2 <= resize(acc_1_0,17) + resize(acc_1_1,17);


          end block;


      end block;


    end block;
  end generate;
  -- map end

  -- map begin
  r_map_0 : for i_2 in result'range generate
  begin
    selection_1 : block
      signal result_8               : signed(15 downto 0);
      signal result_selection_res_4 : boolean;
    begin
      result(i_2) <= result_8;

      result_selection_res_4 <= to_signed(0,16) <= \c$app_arg\(i_2);

      result_8 <= \c$app_arg\(i_2) when result_selection_res_4 else
                  to_signed(0,16);


    end block;
  end generate;
  -- map end

  \c$vec1_0\ <= brain_infer_types.array_of_signed_16'( to_signed(255,16)
                                                     , to_signed(220,16) );

  -- zipWith begin
  zipWith_1 : for i_3 in \c$app_arg_1\'range generate
  begin
    fun_16 : block
      signal result_9                     : signed(15 downto 0);
      signal \c$case_alt_7\               : signed(15 downto 0);
      signal \r'_4\                       : std_logic_vector(15 downto 0);
      signal \c$r'_app_arg_3\             : std_logic_vector(16 downto 0);
      signal r_3                          : signed(16 downto 0);
      signal result_selection_res_5       : boolean;
      signal \c$bv_13\                    : std_logic_vector(15 downto 0);
      signal \c$case_alt_selection_res_4\ : boolean;
      signal \c$bv_14\                    : std_logic_vector(15 downto 0);
      signal \c$bv_15\                    : std_logic_vector(15 downto 0);
      signal \r'_projection_3\            : brain_infer_types.Tuple2;
    begin
      \c$app_arg_1\(i_3) <= result_9;

      \c$bv_13\ <= (\r'_4\);

      result_selection_res_5 <= (( \c$r'_app_arg_3\(\c$r'_app_arg_3\'high) ) xor ( \c$bv_13\(\c$bv_13\'high) )) = '0';

      result_9 <= signed(\r'_4\) when result_selection_res_5 else
                  \c$case_alt_7\;

      \c$bv_14\ <= ((std_logic_vector(\c$vec1_0\(i_3))));

      \c$bv_15\ <= ((std_logic_vector(\c$app_arg_2\(i_3))));

      \c$case_alt_selection_res_4\ <= (( \c$bv_14\(\c$bv_14\'high) ) and ( \c$bv_15\(\c$bv_15\'high) )) = '0';

      \c$case_alt_7\ <= to_signed(32767,16) when \c$case_alt_selection_res_4\ else
                        to_signed(-32768,16);

      \r'_projection_3\ <= (\c$r'_app_arg_3\(\c$r'_app_arg_3\'high downto 16),\c$r'_app_arg_3\(16-1 downto 0));

      \r'_4\ <= \r'_projection_3\.Tuple2_sel1_std_logic_vector_1;

      \c$r'_app_arg_3\ <= (std_logic_vector(r_3));

      r_3 <= resize(\c$vec1_0\(i_3),17) + resize(\c$app_arg_2\(i_3),17);


    end block;
  end generate;
  -- zipWith end

  \c$vec_0\ <= brain_infer_types.array_of_array_of_3_signed_16'( brain_infer_types.array_of_signed_16'( to_signed(0,16)
                                                                                                      , to_signed(2,16)
                                                                                                      , to_signed(2,16) )
                                                               , brain_infer_types.array_of_signed_16'( to_signed(-33,16)
                                                                                                      , to_signed(-34,16)
                                                                                                      , to_signed(-33,16) ) );

  -- map begin
  r_map_1 : for i_5 in \c$app_arg_2\'range generate
  begin
    fun_17 : block
      signal wild_0    : brain_infer_types.array_of_signed_16(0 to 2);
      signal result_10 : signed(15 downto 0);
    begin
      \c$app_arg_2\(i_5) <= result_10;

      -- zipWith begin
      zipWith_2 : for i_4 in wild_0'range generate
      begin
        fun_18 : block
          signal result_11                    : signed(15 downto 0);
          signal \c$case_alt_8\               : signed(15 downto 0);
          signal \c$app_arg_8\                : std_logic_vector(23 downto 0);
          signal \c$app_arg_9\                : std_logic;
          signal \c$app_arg_10\               : std_logic;
          signal \c$app_arg_11\               : std_logic_vector(8 downto 0);
          signal \c$app_arg_12\               : std_logic_vector(7 downto 0);
          signal rL_1                         : std_logic_vector(7 downto 0);
          signal rR_1                         : std_logic_vector(23 downto 0);
          signal ds3_0                        : brain_infer_types.Tuple2_0;
          signal result_selection_res_6       : boolean;
          signal \c$case_alt_selection_res_5\ : boolean;
          signal \c$shI_0\                    : signed(63 downto 0);
          signal \c$bv_16\                    : std_logic_vector(23 downto 0);
          signal \c$bv_17\                    : std_logic_vector(31 downto 0);
        begin
          wild_0(i_4) <= result_11;

          result_selection_res_6 <= ((not \c$app_arg_10\) or \c$app_arg_9\) = '1';

          result_11 <= signed((std_logic_vector(resize(unsigned(\c$app_arg_8\),16)))) when result_selection_res_6 else
                       \c$case_alt_8\;

          \c$case_alt_selection_res_5\ <= ( \c$app_arg_12\(\c$app_arg_12\'high) ) = '0';

          \c$case_alt_8\ <= to_signed(32767,16) when \c$case_alt_selection_res_5\ else
                            to_signed(-32768,16);

          \c$shI_0\ <= (to_signed(8,64));

          capp_arg_8_shiftR : block
            signal sh_0 : natural;
          begin
            sh_0 <=
                -- pragma translate_off
                natural'high when (\c$shI_0\(64-1 downto 31) /= 0) else
                -- pragma translate_on
                to_integer(\c$shI_0\);
            \c$app_arg_8\ <= std_logic_vector(shift_right(unsigned(rR_1),sh_0))
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
              variable result_12       : std_logic;
            begin
              if (arg_1'length < 1) then
                result_12 := '1';
              else
                argi_1 := arg_1;
                if (argi_1'length = 1) then
                  result_12 := argi_1(argi_1'left);
                else
                  half_1   := (argi_1'length + 1) / 2; -- lsb-biased tree
                  upper_1  := and_reduce_0 (argi_1 (argi_1'left downto half_1));
                  lower_1  := and_reduce_0 (argi_1 (half_1 - 1 downto argi_1'right));
                  result_12 := upper_1 and lower_1;
                end if;
              end if;
              return result_12;
            end;
          begin
            \c$app_arg_9\ <= and_reduce_0(\c$app_arg_11\);
          end block;
          -- reduceAnd end

          -- reduceOr begin
          reduceOr_0 : block
            function or_reduce_0 (arg_2 : std_logic_vector) return std_logic is
              variable upper_2, lower_2 : std_logic;
              variable half_2         : integer;
              variable argi_2         : std_logic_vector (arg_2'length - 1 downto 0);
              variable result_13       : std_logic;
            begin
              if (arg_2'length < 1) then
                result_13 := '0';
              else
                argi_2 := arg_2;
                if (argi_2'length = 1) then
                  result_13 := argi_2(argi_2'left);
                else
                  half_2   := (argi_2'length + 1) / 2; -- lsb-biased tree
                  upper_2  := or_reduce_0 (argi_2 (argi_2'left downto half_2));
                  lower_2  := or_reduce_0 (argi_2 (half_2 - 1 downto argi_2'right));
                  result_13 := upper_2 or lower_2;
                end if;
              end if;
              return result_13;
            end;
          begin
            \c$app_arg_10\ <= or_reduce_0(\c$app_arg_11\);
          end block;
          -- reduceOr end

          \c$bv_16\ <= (rR_1);

          \c$app_arg_11\ <= (std_logic_vector'(std_logic_vector'(((std_logic_vector'(0 => ( \c$bv_16\(\c$bv_16\'high) ))))) & std_logic_vector'(\c$app_arg_12\)));

          \c$app_arg_12\ <= rL_1;

          rL_1 <= ds3_0.Tuple2_0_sel0_std_logic_vector_0;

          rR_1 <= ds3_0.Tuple2_0_sel1_std_logic_vector_1;

          \c$bv_17\ <= ((std_logic_vector((result(i_4) * \c$vec_0\(i_5)(i_4)))));

          ds3_0 <= (\c$bv_17\(\c$bv_17\'high downto 24),\c$bv_17\(24-1 downto 0));


        end block;
      end generate;
      -- zipWith end

      fold_0 : block
        signal vec_0     : brain_infer_types.array_of_signed_16(0 to 2);
        signal acc_2_0_1 : signed(15 downto 0);
        signal acc_0_3   : signed(15 downto 0);
        signal acc_0_4   : signed(15 downto 0);
        signal acc_1_0_0 : signed(15 downto 0);
        signal acc_0_5   : signed(15 downto 0);
      begin
        result_10 <= acc_2_0_1;

        vec_0 <= wild_0;

        acc_0_3 <= vec_0(0);

        acc_0_4 <= vec_0(1);

        acc_0_5 <= vec_0(2);

        fun_19 : block
            signal result_14                    : signed(15 downto 0);
            signal \c$case_alt_9\               : signed(15 downto 0);
            signal \r'_5\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_4\             : std_logic_vector(16 downto 0);
            signal r_4                          : signed(16 downto 0);
            signal result_selection_res_7       : boolean;
            signal \c$bv_18\                    : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_6\ : boolean;
            signal \c$bv_19\                    : std_logic_vector(15 downto 0);
            signal \c$bv_20\                    : std_logic_vector(15 downto 0);
            signal \r'_projection_4\            : brain_infer_types.Tuple2;
          begin
            acc_1_0_0 <= result_14;

            \c$bv_18\ <= (\r'_5\);

            result_selection_res_7 <= (( \c$r'_app_arg_4\(\c$r'_app_arg_4\'high) ) xor ( \c$bv_18\(\c$bv_18\'high) )) = '0';

            result_14 <= signed(\r'_5\) when result_selection_res_7 else
                         \c$case_alt_9\;

            \c$bv_19\ <= ((std_logic_vector(acc_0_3)));

            \c$bv_20\ <= ((std_logic_vector(acc_0_4)));

            \c$case_alt_selection_res_6\ <= (( \c$bv_19\(\c$bv_19\'high) ) and ( \c$bv_20\(\c$bv_20\'high) )) = '0';

            \c$case_alt_9\ <= to_signed(32767,16) when \c$case_alt_selection_res_6\ else
                              to_signed(-32768,16);

            \r'_projection_4\ <= (\c$r'_app_arg_4\(\c$r'_app_arg_4\'high downto 16),\c$r'_app_arg_4\(16-1 downto 0));

            \r'_5\ <= \r'_projection_4\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_4\ <= (std_logic_vector(r_4));

            r_4 <= resize(acc_0_3,17) + resize(acc_0_4,17);


          end block;

        fun_20 : block
            signal result_15                    : signed(15 downto 0);
            signal \c$case_alt_10\              : signed(15 downto 0);
            signal \r'_6\                       : std_logic_vector(15 downto 0);
            signal \c$r'_app_arg_5\             : std_logic_vector(16 downto 0);
            signal r_5                          : signed(16 downto 0);
            signal result_selection_res_8       : boolean;
            signal \c$bv_21\                    : std_logic_vector(15 downto 0);
            signal \c$case_alt_selection_res_7\ : boolean;
            signal \c$bv_22\                    : std_logic_vector(15 downto 0);
            signal \c$bv_23\                    : std_logic_vector(15 downto 0);
            signal \r'_projection_5\            : brain_infer_types.Tuple2;
          begin
            acc_2_0_1 <= result_15;

            \c$bv_21\ <= (\r'_6\);

            result_selection_res_8 <= (( \c$r'_app_arg_5\(\c$r'_app_arg_5\'high) ) xor ( \c$bv_21\(\c$bv_21\'high) )) = '0';

            result_15 <= signed(\r'_6\) when result_selection_res_8 else
                         \c$case_alt_10\;

            \c$bv_22\ <= ((std_logic_vector(acc_1_0_0)));

            \c$bv_23\ <= ((std_logic_vector(acc_0_5)));

            \c$case_alt_selection_res_7\ <= (( \c$bv_22\(\c$bv_22\'high) ) and ( \c$bv_23\(\c$bv_23\'high) )) = '0';

            \c$case_alt_10\ <= to_signed(32767,16) when \c$case_alt_selection_res_7\ else
                               to_signed(-32768,16);

            \r'_projection_5\ <= (\c$r'_app_arg_5\(\c$r'_app_arg_5\'high downto 16),\c$r'_app_arg_5\(16-1 downto 0));

            \r'_6\ <= \r'_projection_5\.Tuple2_sel1_std_logic_vector_1;

            \c$r'_app_arg_5\ <= (std_logic_vector(r_5));

            r_5 <= resize(acc_1_0_0,17) + resize(acc_0_5,17);


          end block;


      end block;


    end block;
  end generate;
  -- map end

  -- map begin
  r_map_2 : for i_6 in \output_0\'range generate
  begin
    selection_2 : block
      signal result_16              : signed(15 downto 0);
      signal result_selection_res_9 : boolean;
    begin
      \output_0\(i_6) <= result_16;

      result_selection_res_9 <= to_signed(0,16) <= \c$app_arg_1\(i_6);

      result_16 <= \c$app_arg_1\(i_6) when result_selection_res_9 else
                   to_signed(0,16);


    end block;
  end generate;
  -- map end

  output <= brain_infer_types.toSLV(brain_infer_types.array_of_signed_16'(\output_0\));


end;

