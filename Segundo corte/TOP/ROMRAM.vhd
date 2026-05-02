library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_pkg.all;

entity ROMRAM is
  port(
    CLOCK_50 : in  std_logic;
    rst_n    : in  std_logic;                    -- Botón de Reset (0 pulsado)
    SW       : in  std_logic_vector(1 downto 0); -- Selector de Hz
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of ROMRAM is

  -- Los 5 estados requeridos
  type estado is (LEER_ROM, ESCRIBIR_RAM, LEER_RAM, MOSTRAR, BORRAR_RAM);
  signal estado_actual : estado := LEER_ROM;
  
  signal clk_lento : std_logic;
  signal indice    : integer range 0 to 3 := 0;
  
  -- Buses de datos y direcciones
  signal rom_data : std_logic_vector(7 downto 0);
  signal ram_dout : std_logic_vector(7 downto 0);
  signal ram_din  : std_logic_vector(7 downto 0) := x"00";
  signal ram_we   : std_logic := '0';
  signal addr_bus : std_logic_vector(3 downto 0);
  
  -- Señales para displays (ASCII)
  signal d2, d1, d0 : std_logic_vector(7 downto 0);

begin

  -- Dirección compartida basada en el índice actual
  addr_bus <= std_logic_vector(to_unsigned(indice, 4));

  -- Instancia de componentes (Intocables)
  u_div : contadorvhl port map(CLOCK_50, SW, clk_lento);
  u_rom : rom_sync port map(CLOCK_50, addr_bus, rom_data);
  u_ram : ram_sincrona port map(CLOCK_50, '1', ram_we, addr_bus, ram_din, ram_dout);

  -- Decodificadores (HEX2=Centenas, HEX1=Decenas, HEX0=Unidades)
  u2: dec7seg port map(d2, HEX2);
  u1: dec7seg port map(d1, HEX1);
  u0: dec7seg port map(d0, HEX0);

  -- Lógica de visualización (Convierte el dato de RAM a decimal para los LEDs)
-- Lógica de visualización corregida
  process(ram_dout)
  begin
    case ram_dout is
      when x"AA"  => d2 <= x"31"; d1 <= x"37"; d0 <= x"30"; -- Muestra 170
      when x"55"  => d2 <= x"30"; d1 <= x"38"; d0 <= x"35"; -- Muestra 085
      when x"F0"  => d2 <= x"32"; d1 <= x"34"; d0 <= x"30"; -- Muestra 240
      when x"0F"  => d2 <= x"30"; d1 <= x"31"; d0 <= x"35"; -- Muestra 015
      
      -- Cuando la RAM se limpia (x"00"), ahora mostrará 058
      when others => d2 <= x"30"; d1 <= x"30"; d0 <= x"30"; -- Muestra 000
    end case;
  end process;

  -- MÁQUINA DE ESTADOS CON RESET
  process(clk_lento, rst_n)
  begin
    if rst_n = '0' then               -- Si se pulsa el botón (Lógica negativa)
      estado_actual <= LEER_ROM;
      indice <= 0;
      ram_we <= '0';
    elsif rising_edge(clk_lento) then
      case estado_actual is
        
        when LEER_ROM =>              -- ESTADO A: Lectura desde ROM
          ram_we <= '0';
          estado_actual <= ESCRIBIR_RAM;

        when ESCRIBIR_RAM =>          -- ESTADO B: Escritura en RAM
          ram_din <= rom_data;
          ram_we <= '1';
          estado_actual <= LEER_RAM;

        when LEER_RAM =>              -- ESTADO C: Lectura desde RAM
          ram_we <= '0';
          estado_actual <= MOSTRAR;

        when MOSTRAR =>               -- ESTADO D: Visualización
          estado_actual <= BORRAR_RAM;

        when BORRAR_RAM =>            -- ESTADO E: Limpieza de RAM
          ram_din <= x"00";
          ram_we <= '1';
          if indice = 3 then indice <= 0; else indice <= indice + 1; end if;
          estado_actual <= LEER_ROM;
          
      end case;
    end if;
  end process;

end architecture;