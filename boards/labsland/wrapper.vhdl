-- LabsLand LL_STD_1 interface. Compiled by LabsLand with its own constraints.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main is
  port (
    G_CLOCK_50 : in std_logic;
    V_SW       : in std_logic_vector(9 downto 0);
    V_BT       : in std_logic_vector(3 downto 0);
    G_LEDR     : out std_logic_vector(9 downto 0)
  );
end entity;

architecture rtl of main is
  constant DIAGNOSTIC : boolean := @DIAGNOSTIC@;
  signal key_released : boolean;
  signal predictions : std_logic_vector(9 downto 0);
  signal sw_meta, sw_sync : std_logic_vector(9 downto 0) := (others => '0');
  signal bt_meta, bt_sync : std_logic := '0';
  signal count : natural range 0 to 24999999 := 0;
  signal heartbeat : std_logic := '0';
begin
  -- Use switch 9 for reset so unknown virtual-button polarity cannot hold
  -- the network in reset. SW9=0 runs; SW9=1 resets.
  key_released <= V_SW(9) = '0';
  network : entity work.de1_soc
    port map (
      CLOCK_50 => G_CLOCK_50,
      KEY0 => key_released,
      SW => V_SW(3 downto 0),
      LEDR => predictions
    );

  normal_output : if not DIAGNOSTIC generate
    G_LEDR <= predictions;
  end generate;

  diagnostic_output : if DIAGNOSTIC generate
    process(G_CLOCK_50)
    begin
      if rising_edge(G_CLOCK_50) then
        sw_meta <= V_SW;
        sw_sync <= sw_meta;
        bt_meta <= V_BT(0);
        bt_sync <= bt_meta;
        if count = 24999999 then
          count <= 0;
          heartbeat <= not heartbeat;
        else
          count <= count + 1;
        end if;
      end if;
    end process;
    G_LEDR <= '1' & heartbeat & predictions(1 downto 0)
              & sw_sync(9) & bt_sync & sw_sync(3 downto 0);
  end generate;
end architecture;