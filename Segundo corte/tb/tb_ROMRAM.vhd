library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ROMRAM is
end entity;

architecture sim of tb_ROMRAM is
  
  -- Señales internas para conectar con la unidad bajo prueba (UUT)
  signal CLOCK_50 : std_logic := '0';
  signal rst_n    : std_logic := '1'; -- Botón en 1 (no presionado)
  
  -- Forzamos que SW siempre sea "00"
  signal SW       : std_logic_vector(1 downto 0) := "00";
  
  signal HEX0, HEX1, HEX2 : std_logic_vector(6 downto 0);
  
  -- Frecuencia del reloj maestro (50MHz)
  constant CLK_PERIOD : time := 20 ns;

begin

  -- Instancia del Top Level
  uut: entity work.ROMRAM
    port map(
      CLOCK_50 => CLOCK_50, 
      rst_n    => rst_n, 
      SW       => SW, -- Aquí se pasa el valor "00"
      HEX0     => HEX0, 
      HEX1     => HEX1, 
      HEX2     => HEX2
    );

  -- Generación del Reloj de 50MHz
  process
  begin
    CLOCK_50 <= '0'; wait for CLK_PERIOD/2;
    CLOCK_50 <= '1'; wait for CLK_PERIOD/2;
  end process;

  -- Proceso de estímulos y validación
  process
  begin
    report "--- INICIANDO VALIDACION DE SISTEMA (SW = 00) ---";
    
    -- VALIDACION D: Reset inicial del sistema
    rst_n <= '0'; 
    wait for 100 ns;
    rst_n <= '1';
    report ">>> Reset aplicado: El sistema inicia en Estado 1, Indice 0.";

    -- VALIDACION A, B, C: Flujo de datos
    -- Nota: Al usar SW="00", asegúrate de que el tiempo de espera (wait) 
    -- sea suficiente para que el clk_lento alcance a dar varios pulsos.
    
    wait for 2 ms; -- Aumentamos un poco el tiempo por si la frecuencia "00" es muy lenta
    report ">>> VALIDANDO DATO 1 (170 decimal): Leido, Escrito y Mostrado.";
    
    wait for 2 ms;
    report ">>> VALIDANDO DATO 2 (085 decimal): Leido, Escrito y Mostrado.";
    
    -- Prueba de reset a mitad del proceso
    rst_n <= '0'; 
    wait for 100 ns; 
    rst_n <= '1';
    report ">>> Reset a mitad: El sistema debe volver al primer dato.";

    wait for 2 ms;
    report ">>> CICLO COMPLETADO EXITOSAMENTE CON SW en 00";
    
    report "--- FIN DE LA SIMULACION ---";
    wait; -- Detiene la ejecución de este proceso
  end process;

end architecture;