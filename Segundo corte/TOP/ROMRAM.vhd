library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic
use ieee.numeric_std.all; -- Permite conversiones numéricas como to_unsigned()
use work.mem_pkg.all; -- Importa el paquete con las declaraciones de todos los componentes del proyecto
-- ENTIDAD TOP LEVEL (Define las señales físicas que conectan con los pines de la FPGA)
-- Este es el módulo principal que integra todos los demás componentes del sistema
entity ROMRAM is
  port(
    CLOCK_50 : in  std_logic;                     -- Reloj principal de la FPGA (50 MHz)
    rst_n    : in  std_logic;                     -- Botón de reset con lógica negada (0=pulsado, 1=libre)
    SW       : in  std_logic_vector(1 downto 0);  -- Switches para seleccionar velocidad: 00=1Hz, 01=2Hz, 10=4Hz, 11=8Hz
    HEX0     : out std_logic_vector(6 downto 0);  -- Display de 7 segmentos: dígito de las UNIDADES
    HEX1     : out std_logic_vector(6 downto 0);  -- Display de 7 segmentos: dígito de las DECENAS
    HEX2     : out std_logic_vector(6 downto 0)   -- Display de 7 segmentos: dígito de las CENTENAS
  );
end entity; -- Fin de la entidad
-- ARQUITECTURA (Define la interconexión y lógica interna del sistema completo)
architecture rtl of ROMRAM is
  -- DEFINICIÓN DE LA MÁQUINA DE ESTADOS (FSM)
  -- Los 5 estados describen el ciclo completo de lectura, transferencia y visualización
  type estado is (LEER_ROM, ESCRIBIR_RAM, LEER_RAM, MOSTRAR, BORRAR_RAM); -- Tipo enumerado con los 5 estados
  signal estado_actual : estado := LEER_ROM; -- Señal que guarda el estado en curso, inicia en LEER_ROM
  -- SEÑALES INTERNAS DE CONTROL Y DATOS
  signal clk_lento : std_logic; -- Reloj dividido generado por el contador (1, 2, 4 u 8 Hz)
  signal indice    : integer range 0 to 3 := 0; -- Índice que apunta a la dirección actual (cicla 0→1→2→3→0)
  -- BUSES DE DATOS Y DIRECCIONES
  signal rom_data : std_logic_vector(7 downto 0); -- Dato de 8 bits leído desde la ROM
  signal ram_dout : std_logic_vector(7 downto 0); -- Dato de 8 bits leído desde la RAM
  signal ram_din  : std_logic_vector(7 downto 0) := x"00"; -- Dato de 8 bits a escribir en la RAM
  signal ram_we   : std_logic := '0'; -- Señal de escritura de la RAM (1=escribir, 0=solo leer)
  signal addr_bus : std_logic_vector(3 downto 0); -- Bus de dirección compartido entre ROM y RAM (4 bits)
  -- SEÑALES PARA LOS DISPLAYS (Códigos ASCII de los 3 dígitos a mostrar)
  signal d2, d1, d0 : std_logic_vector(7 downto 0); -- d2=centenas, d1=decenas, d0=unidades
begin -- Inicio de la arquitectura
  -- GENERACIÓN DE LA DIRECCIÓN COMPARTIDA
  -- El índice actual se convierte a 4 bits para usarlo como dirección en ROM y RAM
  addr_bus <= std_logic_vector(to_unsigned(indice, 4)); -- Convierte el entero 'indice' a vector de 4 bits
  -- INSTANCIACIÓN DE COMPONENTES
  -- Divisor de frecuencia: genera clk_lento a partir del reloj de 50 MHz
  u_div : contadorvhl port map(CLOCK_50, SW, clk_lento);
  -- ROM síncrona: recibe la dirección y entrega el dato almacenado en esa celda
  u_rom : rom_sync    port map(CLOCK_50, addr_bus, rom_data);
  -- RAM síncrona: permite leer y escribir datos en tiempo de ejecución
  -- rd_en está fijo en '1' para que la lectura siempre esté habilitada
  u_ram : ram_sincrona port map(CLOCK_50, '1', ram_we, addr_bus, ram_din, ram_dout);
  -- Decodificadores de 7 segmentos: convierten el código ASCII al patrón físico del display
  u2 : dec7seg port map(d2, HEX2); -- Display de centenas
  u1 : dec7seg port map(d1, HEX1); -- Display de decenas
  u0 : dec7seg port map(d0, HEX0); -- Display de unidades
  -- LÓGICA DE VISUALIZACIÓN (Proceso combinacional)
  process(ram_dout) -- Se activa cada vez que cambia el dato leído de la RAM
  begin
    case ram_dout is
      when x"AA" => d2 <= x"31"; d1 <= x"37"; d0 <= x"30"; -- 0xAA (170) → ASCII '1','7','0' → muestra 170
      when x"55" => d2 <= x"30"; d1 <= x"38"; d0 <= x"35"; -- 0x55 ( 85) → ASCII '0','8','5' → muestra 085
      when x"F0" => d2 <= x"32"; d1 <= x"34"; d0 <= x"30"; -- 0xF0 (240) → ASCII '2','4','0' → muestra 240
      when x"0F" => d2 <= x"30"; d1 <= x"31"; d0 <= x"35"; -- 0x0F ( 15) → ASCII '0','1','5' → muestra 015
      when others => d2 <= x"30"; d1 <= x"30"; d0 <= x"30"; -- Cualquier otro valor (ej. 0x00) → muestra 000
    end case;
  end process; -- Fin del proceso de visualización
  -- MÁQUINA DE ESTADOS PRINCIPAL (Proceso síncrono con reset asíncrono)
  -- Controla la secuencia de operaciones sobre ROM y RAM en cada ciclo del reloj lento
  process(clk_lento, rst_n) -- Sensible al reloj lento y al botón de reset
  begin
    -- CONDICIÓN DE RESET ASÍNCRONO
    -- Si se pulsa el botón (rst_n=0), el sistema vuelve al estado inicial sin importar el reloj
    if rst_n = '0' then
      estado_actual <= LEER_ROM; -- Regresa al primer estado de la secuencia
      indice <= 0;               -- Regresa al primer dato de la ROM (dirección 0)
      ram_we <= '0';             -- Desactiva la escritura en RAM para evitar escrituras involuntarias
    -- OPERACIÓN NORMAL: avanza al siguiente estado en cada flanco ascendente del reloj lento
    elsif rising_edge(clk_lento) then
      case estado_actual is
        -- ESTADO A: LEER_ROM
        -- Prepara el bus de dirección y desactiva la escritura en RAM
        -- El dato de la ROM ya está disponible en rom_data tras un ciclo de latencia
        when LEER_ROM =>
          ram_we <= '0'; -- Se asegura que la RAM no escriba mientras se lee la ROM
          estado_actual <= ESCRIBIR_RAM; -- Avanza al siguiente estado
        -- ESTADO B: ESCRIBIR_RAM
        -- Copia el dato leído de la ROM hacia la entrada de la RAM y activa la escritura
        when ESCRIBIR_RAM =>
          ram_din <= rom_data; -- Se pone el dato de la ROM en la entrada de la RAM
          ram_we  <= '1';      -- Se activa la señal de escritura para que la RAM lo guarde
          estado_actual <= LEER_RAM; -- Avanza al siguiente estado
        -- ESTADO C: LEER_RAM
        -- Desactiva la escritura para que la RAM entregue el dato guardado en ram_dout
        when LEER_RAM =>
          ram_we <= '0'; -- Se desactiva la escritura para pasar a modo lectura
          estado_actual <= MOSTRAR; -- Avanza al siguiente estado
        -- ESTADO D: MOSTRAR
        -- El dato ya está disponible en ram_dout y la lógica combinacional actualiza los displays
        -- Este estado no necesita hacer nada adicional: el display se actualiza solo
        when MOSTRAR =>
          estado_actual <= BORRAR_RAM; -- Avanza al siguiente estado
        -- ESTADO E: BORRAR_RAM
        -- Limpia la celda actual escribiendo cero, y avanza al siguiente índice
        -- Al volver a LEER_ROM se usará la siguiente dirección de la ROM
        when BORRAR_RAM =>
          ram_din <= x"00"; -- Se prepara el valor cero para borrar la celda
          ram_we  <= '1';   -- Se activa la escritura para guardar el cero en la RAM
          if indice = 3 then -- Si ya se procesaron los 4 datos (índices 0,1,2,3)
            indice <= 0;     -- Se reinicia al primer dato para repetir el ciclo completo
          else
            indice <= indice + 1; -- Si no, avanza al siguiente dato
          end if;
          estado_actual <= LEER_ROM; -- Regresa al primer estado para procesar el nuevo índice
      end case;
    end if;
  end process; -- Fin del proceso de la máquina de estados
end architecture; -- Fin de la arquitectura