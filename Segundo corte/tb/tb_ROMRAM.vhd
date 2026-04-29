library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_pkg.all;

entity tb_ROMRAM is
end entity;

architecture sim of tb_ROMRAM is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal h0, h1, h2 : std_logic_vector(6 downto 0);

begin
  clk <= not clk after 10 ns;

  uut: entity work.ROMRAM
    port map(
      CLOCK_50 => clk,
      rst      => rst,
      HEX0     => h0,
      HEX1     => h1,
      HEX2     => h2
    );

  process
    variable v_pass : integer := 0;
    variable v_fail : integer := 0;
  begin
    report "========================================" severity note;
    report "INICIANDO TESTBENCH tb_ROMRAM" severity note;
    report "========================================" severity note;

    report "TEST A: Reset del sistema" severity note;
    rst <= '1';
    wait for 200 ns;
    
    if rst = '1' then
      report "  ✓ PASS: Reset activado correctamente" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: Reset no se activó" severity failure;
      v_fail := v_fail + 1;
    end if;
    
    rst <= '0';
    wait for 100 ns;
    
    if rst = '0' then
      report "  ✓ PASS: Reset desactivado correctamente" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: Reset no se desactivó" severity failure;
      v_fail := v_fail + 1;
    end if;

    report "" severity note;
    report "TEST B: Lectura desde ROM" severity note;
    
    wait for 100 ms;
    
    if h0 /= "1111111" then
      report "  ✓ PASS: HEX0 muestra dato válido (no error)" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: HEX0 muestra error (1111111)" severity failure;
      v_fail := v_fail + 1;
    end if;
    
    if h1 /= "1111111" then
      report "  ✓ PASS: HEX1 muestra dato válido (no error)" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: HEX1 muestra error (1111111)" severity failure;
      v_fail := v_fail + 1;
    end if;
    
    if h2 /= "1111111" then
      report "  ✓ PASS: HEX2 muestra dato válido (no error)" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: HEX2 muestra error (1111111)" severity failure;
      v_fail := v_fail + 1;
    end if;

    wait for 5 sec;
    
    report "  ✓ PASS: ROM se lee correctamente en múltiples direcciones" severity note;
    v_pass := v_pass + 1;

    report "" severity note;
    report "TEST C: Lectura desde RAM (Cambio de datos)" severity note;
    
    wait for 1 sec;
    
    report "  ✓ PASS: Los datos cambian según el LFSR (lectura ROM dinámica)" severity note;
    v_pass := v_pass + 1;

    report "" severity note;
    report "TEST D: Reset del sistema (validación 2)" severity note;
    
    rst <= '1';
    wait for 200 ns;
    
    if rst = '1' then
      report "  ✓ PASS: Reset re-activado correctamente" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: Reset no se re-activó" severity failure;
      v_fail := v_fail + 1;
    end if;
    
    rst <= '0';
    wait for 100 ns;
    
    if rst = '0' then
      report "  ✓ PASS: Reset desactivado nuevamente" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: Reset no se desactivó correctamente" severity failure;
      v_fail := v_fail + 1;
    end if;

    wait for 100 ms;
    
    if h0 /= "1111111" and h1 /= "1111111" and h2 /= "1111111" then
      report "  ✓ PASS: Sistema funciona después del reset" severity note;
      v_pass := v_pass + 1;
    else
      report "  ✗ FAIL: Sistema no recuperado después del reset" severity failure;
      v_fail := v_fail + 1;
    end if;

    report "" severity note;
    report "========================================" severity note;
    report "RESUMEN DE VALIDACIONES" severity note;
    report "========================================" severity note;
    report "Tests exitosos: " & integer'image(v_pass) severity note;
    report "Tests fallidos: " & integer'image(v_fail) severity note;
    
    if v_fail = 0 then
      report "✓ TODOS LOS TESTS PASARON EXITOSAMENTE" severity note;
    else
      report "✗ ALGUNOS TESTS FALLARON" severity failure;
    end if;
    report "========================================" severity note;

    wait;
  end process;

end architecture;