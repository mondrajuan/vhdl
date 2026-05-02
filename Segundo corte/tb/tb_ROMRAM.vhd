library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic
use work.mem_pkg.all; -- Importa el paquete con las declaraciones de todos los componentes del proyecto
-- ENTIDAD DEL TESTBENCH (No tiene puertos: es un módulo de simulación cerrado)
-- Su función es generar estímulos y observar las respuestas del sistema bajo prueba (UUT)
entity tb_ROMRAM is
-- Sin puertos: los testbench no tienen pines externos, todo ocurre internamente
end entity; -- Fin de la entidad
-- ARQUITECTURA DE SIMULACIÓN
architecture sim of tb_ROMRAM is
  -- SEÑALES INTERNAS (Simulan los pines físicos que tendría la FPGA real)
  signal clk_50MHz : std_logic := '0'; -- Señal de reloj inicializada en 0 (arranca en bajo)
  signal reset_n   : std_logic := '1'; -- Botón de reset: inicia en 1 (no presionado, lógica negada)
  -- SELECTOR DE VELOCIDAD FORZADO AL MÁXIMO
  -- SW="11" selecciona 8 Hz en el divisor de frecuencia
  -- Esto reduce el tiempo real de simulación: cada estado de la FSM dura ~62.5 ms en vez de 500 ms
  signal switches  : std_logic_vector(1 downto 0) := "11"; -- Velocidad máxima: 8 Hz (divisor = 6 250 000)
  -- SEÑALES DE SALIDA OBSERVABLES EN EL SIMULADOR
  signal hex0 : std_logic_vector(6 downto 0); -- Observación del display de unidades
  signal hex1 : std_logic_vector(6 downto 0); -- Observación del display de decenas
  signal hex2 : std_logic_vector(6 downto 0); -- Observación del display de centenas
  -- CONSTANTE DE TEMPORIZACIÓN DEL RELOJ MAESTRO
  constant CLK_PERIOD : time := 20 ns; -- Periodo = 1 / 50 MHz = 20 nanosegundos
begin -- Inicio de la arquitectura de simulación
  -- INSTANCIACIÓN DE LA UNIDAD BAJO PRUEBA (UUT)
  uut : entity work.ROMRAM
    port map (
      CLOCK_50 => clk_50MHz, -- Reloj del testbench → reloj de 50 MHz del sistema
      rst_n    => reset_n,   -- Reset del testbench → botón de reset del sistema
      SW       => switches,  -- Switches forzados a "11" → divisor selecciona 8 Hz
      HEX0     => hex0,      -- Salida unidades → señal observable en ModelSim
      HEX1     => hex1,      -- Salida decenas  → señal observable en ModelSim
      HEX2     => hex2       -- Salida centenas → señal observable en ModelSim
    );
  -- GENERADOR DE RELOJ CONTINUO (Proceso que corre indefinidamente)
  reloj_proc : process -- Sin lista de sensibilidad: se ejecuta en bucle infinito
  begin
    clk_50MHz <= '0'; wait for CLK_PERIOD / 2; -- Mantiene el reloj en bajo durante 10 ns
    clk_50MHz <= '1'; wait for CLK_PERIOD / 2; -- Mantiene el reloj en alto durante 10 ns
  end process; -- El proceso vuelve a empezar automáticamente generando el reloj continuo
  -- PROCESO PRINCIPAL DE ESTÍMULOS
  estimulos_proc : process -- Sin lista de sensibilidad: se ejecuta en secuencia una sola vez
  begin
    report "--- INICIANDO SIMULACION (TIEMPO REAL) ---"; -- Mensaje de inicio visible en la consola
    -- PASO 1: RESET INICIAL DEL SISTEMA
    reset_n <= '0';    -- Se activa el reset (lógica negada: 0 = pulsado)
    wait for 100 ns;   -- Se mantiene el reset durante 100 ns (5 ciclos de reloj de 50 MHz)
    reset_n <= '1';    -- Se libera el reset: la FSM comienza a operar normalmente
    report ">>> Reset liberado. FSM en LEER_ROM."; -- Confirmación del estado inicial en consola

    -- PASO 2: ESPERA DE 6 SEGUNDOS PARA CUBRIR EL CICLO COMPLETO
    -- Se esperan 6 segundos para garantizar que todos los datos (170, 085, 240, 015)
    -- completen al menos dos ciclos completos y sean visibles en las ondas del simulador
    wait for 6 sec; -- Espera de 6 segundos de tiempo simulad
    report "--- SIMULACION COMPLETADA ---"; -- Mensaje de cierre visible en la consola
    -- PASO 3: EL FIN DE LA SIMULACIÓN
    assert false report "Fin forzado de la simulación." severity failure; -- Detiene el simulador
    wait;
  end process; -- Fin del proceso de estímulos
end architecture; -- Fin de la arquitectura de simulación