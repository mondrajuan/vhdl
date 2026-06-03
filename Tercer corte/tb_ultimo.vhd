library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite el manejo de niveles lógicos en la simulación
use ieee.numeric_std.all; -- Habilita operaciones y tipos numéricos

-- ENTIDAD DEL TESTBENCH (Las entidades de bancos de pruebas son cerradas y no poseen pines externos)
entity tb_ultimo is
end entity tb_ultimo;

-- ARQUITECTURA (Define las señales de estímulo y la conexión con el componente bajo prueba DUT)
architecture testbench of tb_ultimo is

  -- Declaración del componente "ultimo" (Bloque principal de hardware que vamos a testear)
  component ultimo
    port (
      clk            : in  std_logic;                     -- Entrada para el reloj simulado
      switches       : in  std_logic_vector(2 downto 0);  -- Entrada para simular los interruptores físicos
      led_out        : out std_logic;                     -- Salida para observar el comportamiento del LED
      ventilador_out : out std_logic                      -- Salida para observar el comportamiento del ventilador
    );
  end component;

  -- SEÑALES INTERNAS PARA CONECTAR EL ENTORNO DE PRUEBA CON EL COMPONENTE
  signal clk            : std_logic := '0';                     -- Inicializa la señal de reloj en '0'
  signal switches       : std_logic_vector(2 downto 0) := "000"; -- Inicializa los interruptores simulados en "000"
  signal led_out        : std_logic;                             -- Monitorea el estado de salida del LED
  signal ventilador_out : std_logic;                             -- Monitorea el estado de salida del ventilador
  
  -- CONSTANTE DE TIEMPO PARA LA FRECUENCIA DE TRABAJO
  constant CLK_PERIOD   : time := 10 ns; -- Define un ciclo completo de reloj cada 10 ns (Simula 100 MHz de velocidad)

begin

  -- INSTANCIACIÓN DEL COMPONENTE BAJO PRUEBA (DUT - Device Under Test)
  dut : ultimo
    port map (
      clk            => clk,            -- Conecta el generador de reloj al puerto del componente
      switches       => switches,       -- Conecta los estímulos de switches al puerto del componente
      led_out        => led_out,        -- Captura la respuesta del LED del componente
      ventilador_out => ventilador_out  -- Captura la respuesta del ventilador del componente
    );

  -- PROCESO GENERADOR DE RELOJ: Genera una onda cuadrada infinita
  clk_proc : process
  begin
    clk <= '0';                 -- Pone el reloj en nivel bajo ('0')
    wait for CLK_PERIOD / 2;    -- Espera durante medio período (5 ns)
    clk <= '1';                 -- Cambia el reloj a nivel alto ('1')
    wait for CLK_PERIOD / 2;    -- Espera el otro medio período (5 ns)
  end process;

  -- PROCESO DE ESTÍMULOS: Aplica secuencias automáticas en los switches para verificar el funcionamiento
  stimulus : process
  begin
    wait for 50 ns;             -- Espera de inicialización inicial para estabilizar transitorios internos
    
    switches <= "000";          -- ESTÍMULO 1: Modo manual activo, interruptores apagados
    wait for 1000 ns;           -- Mantiene el estado durante 1 microsegundo completo

    switches <= "010";          -- ESTÍMULO 2: Modo manual activo, enciende el switch del LED
    wait for 1000 ns;           -- Observa la transferencia del dato a través del procesador

    switches <= "001";          -- ESTÍMULO 3: Modo manual activo, enciende el switch del ventilador
    wait for 1000 ns;           -- Mantiene el estímulo en observación

    switches <= "011";          -- ESTÍMULO 4: Modo manual activo, enciende LED y ventilador en simultáneo
    wait for 1000 ns;           -- Espera el procesamiento

    switches <= "100";          -- ESTÍMULO 5: Cambia al Modo Automático (Bit de mayor peso en '1')
    wait for 4000 ns;           -- Deja correr por 4 microsegundos para observar los ciclos automáticos internos
    
    -- Mensaje de alerta informativa para detener la simulación de forma limpia en la terminal de ModelSim
    assert false report "Simulacion terminada." severity note;
    wait;                       -- Detiene permanentemente el proceso de estímulos para que no se repita
  end process;

end architecture testbench;
