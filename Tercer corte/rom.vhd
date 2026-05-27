library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom is
  port (
    addr : in  std_logic_vector(7 downto 0);
    dout : out std_logic_vector(7 downto 0)
  );
end entity rom;

architecture behave of rom is
  type rom_type is array (0 to 255) of std_logic_vector(7 downto 0);
  signal rom_data : rom_type := (
    0 => x"01",
    1 => x"FF",
    2 => x"03",
    3 => x"02",
    4 => x"FE",
    5 => x"08",
    6 => x"00",
    others => x"00"
  );
begin
  dout <= rom_data(to_integer(unsigned(addr)));
end architecture behave;