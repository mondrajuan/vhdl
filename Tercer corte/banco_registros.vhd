library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity banco_registros is
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    addr_w   : in std_logic_vector(1 downto 0);
    addr_r1  : in std_logic_vector(1 downto 0);
    addr_r2  : in std_logic_vector(1 downto 0);
    din      : in std_logic_vector(7 downto 0);
    wen      : in std_logic;
    dout1    : out std_logic_vector(7 downto 0);
    dout2    : out std_logic_vector(7 downto 0)
  );
end entity banco_registros;

architecture rtl of banco_registros is
  type reg_array is array (0 to 3) of std_logic_vector(7 downto 0);
  signal regs : reg_array;
begin
  process(clk, rst)
  begin
    if rst = '1' then
      regs <= (others => (others => '0'));
    elsif rising_edge(clk) then
      if wen = '1' then
        regs(to_integer(unsigned(addr_w))) <= din;
      end if;
    end if;
  end process;
  dout1 <= regs(to_integer(unsigned(addr_r1)));
  dout2 <= regs(to_integer(unsigned(addr_r2)));
end architecture rtl;