library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ultimo is
end entity tb_ultimo;

architecture testbench of tb_ultimo is

  component ultimo
    port (
      clk            : in  std_logic;
      switches       : in  std_logic_vector(2 downto 0);
      led_out        : out std_logic;
      ventilador_out : out std_logic
    );
  end component;

  signal clk            : std_logic := '0';
  signal switches       : std_logic_vector(2 downto 0) := "000";
  signal led_out        : std_logic;
  signal ventilador_out : std_logic;
  
  constant CLK_PERIOD   : time := 10 ns;

begin

  dut : ultimo
    port map (
      clk            => clk,
      switches       => switches,
      led_out        => led_out,
      ventilador_out => ventilador_out
    );

  clk_proc : process
  begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
  end process;

  stimulus : process
  begin
    wait for 50 ns;

    switches <= "000";
    wait for 1000 ns; 

    switches <= "010";
    wait for 1000 ns;

    switches <= "001";
    wait for 1000 ns;

    switches <= "011";
    wait for 1000 ns;

    switches <= "100";
    wait for 4000 ns;

    assert false report "Simulacion terminada." severity note;
    wait;
  end process;

end architecture testbench;