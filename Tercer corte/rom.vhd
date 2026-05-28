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
    0 => x"01", -- LD (Cargar al registro R0)
    1 => x"FF", -- ...desde la ENTRADA
    2 => x"02", -- ST (Guardar)
    3 => x"10", -- ...hacia la RAM en la direccion 10
    4 => x"01", -- LD (Cargar)
    5 => x"10", -- ...desde la RAM direccion 10
    6 => x"00", -- AND R0, R0 (Pasar por la ALU para procesar el dato)
    7 => x"02", -- ST (Guardar el resultado de la ALU)
    8 => x"11", -- ...hacia la RAM en la direccion 11
    9 => x"01", -- LD (Cargar)
   10 => x"11", -- ...desde la RAM direccion 11
   11 => x"02", -- ST (Guardar)
   12 => x"FE", -- ...hacia los Leds/Ventilador (SALIDA)
   13 => x"08", -- JMP (Volver a empezar)
   14 => x"00", -- ...a la direccion 00
   others => x"00"
  );
begin
  dout <= rom_data(to_integer(unsigned(addr)));
end architecture behave;