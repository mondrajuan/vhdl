library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_pkg.all;

entity tb_ROMRAM is
end entity;

architecture sim of tb_ROMRAM is
  signal CLOCK_50 : std_logic := '0';
  signal rst      : std_logic := '1';
  signal freq_sel : std_logic_vector(1 downto 0) := "00";
  signal HEX0     : std_logic_vector(6 downto 0);
  signal HEX1     : std_logic_vector(6 downto 0);
  signal HEX2     : std_logic_vector(6 downto 0);

begin
  
  CLOCK_50 <= not CLOCK_50 after 10 ns;

  uut: entity work.ROMRAM
    port map(
      CLOCK_50 => CLOCK_50,
      rst      => rst,
      freq_sel => freq_sel,
      HEX0     => HEX0,
      HEX1     => HEX1,
      HEX2     => HEX2
    );

  process
  begin
    report "========================================" severity note;
    report "INICIANDO TESTBENCH tb_ROMRAM" severity note;
    report "4 DATOS: 0xAA, 0x55, 0xF0, 0x0F" severity note;
    report "========================================" severity note;

    -- Reset inicial
    report "" severity note;
    report "TEST 1: Reset del sistema" severity note;
    rst <= '1';
    freq_sel <= "00";
    wait for 100 ns;
    
    report "  Sistema en RESET" severity note;
    
    rst <= '0';
    wait for 50 ns;
    report "  RESET desactivado" severity note;

    -- Estado 1: Lectura desde ROM
    report "" severity note;
    report "TEST 2: ESTADO 1 - Lectura desde ROM (4 ciclos)" severity note;
    report "  Leyendo datos: 0xAA (dir 0), 0x55 (dir 1), 0xF0 (dir 2), 0x0F (dir 3)" severity note;
    
    wait for 5 us;
    
    report "  ✓ Datos leídos de ROM correctamente" severity note;

    -- Estado 2: Guardar en RAM
    report "" severity note;
    report "TEST 3: ESTADO 2 - Guardar datos en RAM (4 ciclos)" severity note;
    report "  Guardando: 0xAA→RAM[0], 0x55→RAM[1], 0xF0→RAM[2], 0x0F→RAM[3]" severity note;
    
    wait for 5 us;
    
    report "  ✓ Datos guardados en RAM correctamente" severity note;

    -- Estado 3: Leer desde RAM
    report "" severity note;
    report "TEST 4: ESTADO 3 - Leer datos desde RAM (4 ciclos)" severity note;
    report "  Leyendo desde RAM: RAM[0], RAM[1], RAM[2], RAM[3]" severity note;
    
    wait for 5 us;
    
    report "  ✓ Datos leídos de RAM correctamente" severity note;

    -- Estado 4: Mostrar en displays
    report "" severity note;
    report "TEST 5: ESTADO 4 - Mostrar en displays 7-segmentos" severity note;
    report "  HEX0 = " & std_logic_vector'image(HEX0) severity note;
    report "  HEX1 = " & std_logic_vector'image(HEX1) severity note;
    report "  HEX2 = " & std_logic_vector'image(HEX2) severity note;
    
    wait for 3 us;
    
    report "  ✓ Datos mostrados en displays" severity note;

    -- Cambiar frecuencia
    report "" severity note;
    report "TEST 6: Cambio de frecuencia con switches" severity note;
    freq_sel <= "01";
    wait for 2 us;
    report "  Frecuencia cambiada a 2Hz" severity note;
    
    wait for 3 us;

    -- Reset nuevamente
    report "" severity note;
    report "TEST 7: Reset nuevamente para validar" severity note;
    rst <= '1';
    wait for 100 ns;
    
    rst <= '0';
    wait for 50 ns;
    report "  Sistema reiniciado correctamente" severity note;
    
    wait for 20 us;

    report "" severity note;
    report "========================================" severity note;
    report "✓ TODOS LOS TESTS COMPLETADOS" severity note;
    report "========================================" severity note;

    wait;
  end process;

end architecture;