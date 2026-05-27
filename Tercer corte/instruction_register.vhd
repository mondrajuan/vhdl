library ieee;
use ieee.std_logic_1164.all;

entity instruction_register is
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    en    : in std_logic;
    din   : in std_logic_vector(7 downto 0);
    dout  : out std_logic_vector(7 downto 0)
  );
end entity instruction_register;

architecture rtl of instruction_register is
  signal instr : std_logic_vector(7 downto 0);
begin
  process(clk, rst)
  begin
    if rst = '1' then
      instr <= (others => '0');
    elsif rising_edge(clk) then
      if en = '1' then
        instr <= din;
      end if;
    end if;
  end process;
  dout <= instr;
end architecture rtl;