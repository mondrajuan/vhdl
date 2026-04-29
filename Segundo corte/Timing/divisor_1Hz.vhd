library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity divisor_1Hz is
  port(
    clk50 : in  std_logic;
    clk1  : out std_logic
  );
end entity;

architecture rtl of divisor_1Hz is
  signal cnt : unsigned(25 downto 0) := (others => '0');
  signal s   : std_logic := '0';
  
begin
  process(clk50)
  begin
    if rising_edge(clk50) then
      if cnt = 24999999 then 
        cnt <= (others => '0');
        s <= not s;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  
  clk1 <= s;
  
end architecture;