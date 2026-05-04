library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic
use work.mem_pkg.all; -- Importa el paquete de memoria

-- ENTIDAD DEL TESTBENCH (Módulo de simulación sin puertos externos)
entity tb_ROMRAM is
end entity;

-- ARQUITECTURA DE SIMULACIÓN
architecture sim of tb_ROMRAM is
  -- SEÑALES INTERNAS PARA ESTÍMULOS
  signal clk_50MHz : std_logic := '0'; -- Reloj maestro de 50 MHz[cite: 7]
  signal reset_n   : std_logic := '1'; -- Señal de reset activa en bajo[cite: 7]
  signal switches  : std_logic_vector(1 downto 0) := "00"; -- No afecta en modo simulación
  
  -- SEÑALES DE OBSERVACIÓN
  signal hex0, hex1, hex2 : std_logic_vector(6 downto 0); -- Salidas de los displays[cite: 7]
  
  -- CONSTANTE DE TIEMPO
  constant CLK_PERIOD : time := 20 ns; -- Periodo para frecuencia de 50 MHz[cite: 7]
begin 

  -- INSTANCIACIÓN DE LA UNIDAD BAJO PRUEBA (UUT)
  -- Se activa SIMULATION => true para omitir el divisor de frecuencia en ModelSim
  uut : entity work.ROMRAM
    generic map ( SIMULATION => true )
    port map (
      CLOCK_50 => clk_50MHz,
      rst_n    => reset_n,
      SW       => switches,
      HEX0     => hex0,
      HEX1     => hex1,
      HEX2     => hex2
    );

  -- GENERADOR DE RELOJ (Simula el cristal de la FPGA)
  reloj_proc : process 
  begin
    clk_50MHz <= '0'; wait for CLK_PERIOD / 2; 
    clk_50MHz <= '1'; wait for CLK_PERIOD / 2; 
  end process; 

  -- PROCESO DE ESTÍMULOS (Define la secuencia de la prueba)
  estimulos_proc : process 
  begin
    report "--- INICIANDO PRUEBA DE RESET ---"; 
    
    -- PASO 1: VERIFICAR RESET (Debe mostrar 000 en HEX2, HEX1, HEX0)
    reset_n <= '0';    
    wait for 100 ns; -- Espera breve con reset activado
    
    report "--- LIBERANDO RESET Y PROCESANDO MEMORIA ---"; 
    
    -- PASO 2: OPERACIÓN NORMAL
    reset_n <= '1'; -- Libera el sistema para que la FSM comience
    
    -- Espera de 2 microsegundos: Con el generic de simulación, esto es tiempo
    -- suficiente para ver cómo se cargan y borran todos los datos de la ROM.
    wait for 2 us; 
    
    report "--- SIMULACION COMPLETADA EXITOSAMENTE ---"; 
    
    -- FINALIZACIÓN DE LA SIMULACIÓN
    assert false report "Fin de la simulación" severity failure; 
    wait;
  end process; 
end architecture;