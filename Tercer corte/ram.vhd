library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    addr  : in std_logic_vector(7 downto 0);
    din   : in std_logic_vector(7 downto 0);
    wen   : in std_logic;
    dout  : out std_logic_vector(7 downto 0)
  );
end entity ram;

architecture rtl of ram is
  type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
  signal ram_data : ram_type;
begin
  process(clk, rst)
  begin
    if rst = '1' then
      ram_data <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if wen = '1' then
        ram_data(to_integer(unsigned(addr))) <= din;
      end if;
    end if;
  end process;
  dout <= ram_data(to_integer(unsigned(addr)));
end architecture rtl;