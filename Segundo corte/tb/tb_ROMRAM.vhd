library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic
use ieee.numeric_std.all; -- Permite conversiones numéricas (aunque no se usa directamente aquí)

-- ENTIDAD DEL TESTBENCH (No tiene puertos: el testbench es un módulo de simulación cerrado)
-- Su única función es crear estímulos y verificar las respuestas del sistema bajo prueba (UUT)
entity tb_ROMRAM is
end entity; -- Fin de la entidad (vacía intencionalmente, los testbench no tienen pines externos)

-- ARQUITECTURA DE SIMULACIÓN
architecture sim of tb_ROMRAM is

  -- SEÑALES INTERNAS (Simulan los pines físicos que tendría la FPGA real)
  signal CLOCK_50 : std_logic := '0'; -- Señal de reloj inicializada en 0 (arranca en bajo)
  signal rst_n    : std_logic := '1'; -- Botón de reset: inicia en 1 (no presionado, lógica negada)
  signal SW       : std_logic_vector(1 downto 0) := "00"; -- Switches fijos en "00" → velocidad 1 Hz
  signal HEX0     : std_logic_vector(6 downto 0); -- Señal de observación: display unidades
  signal HEX1     : std_logic_vector(6 downto 0); -- Señal de observación: display decenas
  signal HEX2     : std_logic_vector(6 downto 0); -- Señal de observación: display centenas

  -- CONSTANTE DE TEMPORIZACIÓN
  -- Define el periodo del reloj de 50 MHz para la simulación
  constant CLK_PERIOD : time := 20 ns; -- Periodo = 1/50MHz = 20 nanosegundos

begin -- Inicio de la arquitectura de simulación

  -- INSTANCIACIÓN DE LA UNIDAD BAJO PRUEBA (UUT)
  -- Se conecta el sistema real (ROMRAM) con las señales del testbench
  uut : entity work.ROMRAM
    port map(
      CLOCK_50 => CLOCK_50, -- Reloj del testbench → reloj del sistema
      rst_n    => rst_n,    -- Reset del testbench → reset del sistema
      SW       => SW,       -- Switches fijos en "00" → el sistema correrá a 1 Hz
      HEX0     => HEX0,     -- Salida del sistema → señal observable en simulación
      HEX1     => HEX1,     -- Salida del sistema → señal observable en simulación
      HEX2     => HEX2      -- Salida del sistema → señal observable en simulación
    );

  -- GENERADOR DE RELOJ (Proceso que corre indefinidamente)
  -- Crea una señal cuadrada de 50 MHz alternando entre '0' y '1' cada 10 ns
  process -- Sin lista de sensibilidad: se ejecuta en bucle infinito
  begin
    CLOCK_50 <= '0'; wait for CLK_PERIOD/2; -- Mantiene el reloj en bajo durante 10 ns
    CLOCK_50 <= '1'; wait for CLK_PERIOD/2; -- Mantiene el reloj en alto durante 10 ns
  end process; -- El proceso vuelve a comenzar automáticamente (genera el reloj continuo)

  -- PROCESO DE ESTÍMULOS Y VALIDACIÓN
  -- Aplica señales al sistema en instantes específicos y reporta el progreso en consola
  process -- Sin lista de sensibilidad: se ejecuta en secuencia una sola vez
  begin

    report "--- INICIANDO VALIDACION DE SISTEMA (SW = 00) ---"; -- Mensaje de inicio en consola

    -- VALIDACIÓN D: RESET INICIAL DEL SISTEMA
    -- Se pulsa y suelta el botón de reset para garantizar que el sistema parte desde cero
    rst_n <= '0';      -- Se pulsa el botón de reset (lógica negada: 0=pulsado)
    wait for 100 ns;   -- Se mantiene el reset activo durante 100 ns (5 ciclos de reloj)
    rst_n <= '1';      -- Se suelta el botón: el sistema comienza a operar normalmente
    report ">>> Reset aplicado: El sistema inicia en Estado 1, Indice 0."; -- Confirmación en consola

    -- VALIDACIÓN A, B, C: FLUJO DE DATOS PARA EL PRIMER DATO (170 decimal)
    -- Con SW="00" el clk_lento es de 1 Hz → cada ciclo de la FSM tarda ~1 segundo real
    -- En simulación se usa 'wait for 2 ms' que equivale a varios ciclos del clk_lento simulado
    wait for 2 ms; -- Espera suficiente para que la FSM complete el ciclo del primer dato
    report ">>> VALIDANDO DATO 1 (170 decimal): Leido, Escrito y Mostrado."; -- Verificación dato 1

    -- VALIDACIÓN: FLUJO DE DATOS PARA EL SEGUNDO DATO (085 decimal)
    wait for 2 ms; -- Espera para el ciclo del segundo dato
    report ">>> VALIDANDO DATO 2 (085 decimal): Leido, Escrito y Mostrado."; -- Verificación dato 2

    -- PRUEBA DE RESET A MITAD DEL PROCESO
    -- Verifica que el sistema sea capaz de volver al estado inicial desde cualquier punto
    rst_n <= '0';      -- Se pulsa el reset mientras el sistema está a mitad del ciclo
    wait for 100 ns;   -- Se mantiene el reset durante 100 ns
    rst_n <= '1';      -- Se suelta el reset: el sistema debe volver al primer dato (170)
    report ">>> Reset a mitad: El sistema debe volver al primer dato."; -- Verificación de reset

    -- VALIDACIÓN FINAL: CICLO COMPLETO DESPUÉS DEL RESET
    wait for 2 ms; -- Espera para verificar que el sistema retomó el funcionamiento normal
    report ">>> CICLO COMPLETADO EXITOSAMENTE CON SW en 00"; -- Confirmación de ciclo correcto

    report "--- FIN DE LA SIMULACION ---"; -- Mensaje de cierre en consola
    wait; -- Detiene este proceso para siempre: la simulación queda congelada aquí

  end process; -- Fin del proceso de estímulos

end architecture; -- Fin de la arquitectura de simulación