library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic
use ieee.numeric_std.all; -- Permite conversiones numéricas como to_unsigned()
use work.mem_pkg.all; -- Importa el paquete con las declaraciones de todos los componentes del proyecto

-- ENTIDAD TOP LEVEL (Define las señales físicas que conectan con los pines de la FPGA)
entity ROMRAM is
  generic (
    SIMULATION : boolean := false -- Parámetro para acelerar el reloj: true=ModelSim, false=FPGA real
  );
  port(
    CLOCK_50 : in  std_logic;                     -- Reloj principal de la FPGA (50 MHz)
    rst_n    : in  std_logic;                     -- Botón de reset con lógica negada (0=pulsado, 1=libre)[cite: 6]
    SW       : in  std_logic_vector(1 downto 0);  -- Switches para seleccionar velocidad: 00=1Hz, 01=2Hz, 10=4Hz, 11=8Hz[cite: 6]
    HEX0     : out std_logic_vector(6 downto 0);  -- Display de 7 segmentos: dígito de las UNIDADES[cite: 6]
    HEX1     : out std_logic_vector(6 downto 0);  -- Display de 7 segmentos: dígito de las DECENAS[cite: 6]
    HEX2     : out std_logic_vector(6 downto 0)   -- Display de 7 segmentos: dígito de las CENTENAS[cite: 6]
  );
end entity;

-- ARQUITECTURA (Define la interconexión y lógica interna del sistema completo)
architecture rtl of ROMRAM is
  -- DEFINICIÓN DE LA MÁQUINA DE ESTADOS (FSM)
  type estado is (LEER_ROM, ESCRIBIR_RAM, LEER_RAM, MOSTRAR, BORRAR_RAM); -- Estados para el ciclo de transferencia[cite: 6]
  signal estado_actual : estado := LEER_ROM; -- Señal que guarda el estado en curso, inicia en LEER_ROM[cite: 6]
  
  -- SEÑALES INTERNAS DE CONTROL Y DATOS
  signal clk_lento  : std_logic; -- Reloj final que controlará la máquina de estados
  signal clk_div    : std_logic; -- Reloj generado por el divisor de frecuencia físico[cite: 6]
  signal indice     : integer range 0 to 3 := 0; -- Dirección actual del dato (cicla 0 a 3)[cite: 6]
  
  -- BUSES DE DATOS Y DIRECCIONES
  signal rom_data   : std_logic_vector(7 downto 0); -- Dato de 8 bits leído desde la ROM[cite: 6]
  signal ram_dout   : std_logic_vector(7 downto 0); -- Dato de 8 bits leído desde la RAM[cite: 6]
  signal ram_din    : std_logic_vector(7 downto 0) := x"00"; -- Dato de 8 bits a escribir en la RAM[cite: 6]
  signal ram_we     : std_logic := '0'; -- Señal de escritura de la RAM (1=escribir, 0=leer)[cite: 6]
  signal addr_bus   : std_logic_vector(3 downto 0); -- Bus de dirección compartido (4 bits)[cite: 6]
  
  -- SEÑALES PARA LOS DISPLAYS (Códigos ASCII de los 3 dígitos)
  signal d2, d1, d0 : std_logic_vector(7 downto 0); -- d2=centenas, d1=decenas, d0=unidades[cite: 6]
begin

  -- SELECCIÓN DEL RELOJ DE OPERACIÓN
  -- Si SIMULATION es true, usa el reloj de 50 MHz directamente para que el TB sea rápido.
  -- Si es false, usa el reloj lento generado por el contadorvhl.
  clk_lento <= CLOCK_50 when SIMULATION else clk_div;

  -- GENERACIÓN DE LA DIRECCIÓN COMPARTIDA
  addr_bus <= std_logic_vector(to_unsigned(indice, 4)); -- Convierte el entero a vector de 4 bits[cite: 6]

  -- INSTANCIACIÓN DE COMPONENTES
  u_div : contadorvhl port map(CLOCK_50, SW, clk_div); -- Divisor de frecuencia[cite: 6]
  u_rom : rom_sync    port map(CLOCK_50, addr_bus, rom_data); -- Memoria ROM síncrona[cite: 6]
  u_ram : ram_sincrona port map(CLOCK_50, '1', ram_we, addr_bus, ram_din, ram_dout); -- Memoria RAM síncrona[cite: 6]
  u2 : dec7seg port map(d2, HEX2); -- Decodificador centenas[cite: 6]
  u1 : dec7seg port map(d1, HEX1); -- Decodificador decenas[cite: 6]
  u0 : dec7seg port map(d0, HEX0); -- Decodificador unidades[cite: 6]

  -- LÓGICA DE VISUALIZACIÓN Y RESET DE DISPLAYS
  -- Este proceso asigna los caracteres ASCII según el dato leído de la RAM
  process(ram_dout, rst_n)
  begin
    -- Si el botón de reset está pulsado (rst_n = '0'), se fuerza la visualización de "000"
    if rst_n = '0' then
      d2 <= x"30"; d1 <= x"30"; d0 <= x"30"; -- x"30" es el código ASCII para el dígito '0'[cite: 2]
    else
      -- Si no hay reset, se asignan los valores según el contenido de la RAM[cite: 6]
      case ram_dout is
        when x"AA" => d2 <= x"31"; d1 <= x"37"; d0 <= x"30"; -- 0xAA (170) → Muestra 170[cite: 6]
        when x"55" => d2 <= x"30"; d1 <= x"38"; d0 <= x"35"; -- 0x55 (085) → Muestra 085[cite: 6]
        when x"F0" => d2 <= x"32"; d1 <= x"34"; d0 <= x"30"; -- 0xF0 (240) → Muestra 240[cite: 6]
        when x"0F" => d2 <= x"30"; d1 <= x"31"; d0 <= x"35"; -- 0x0F (015) → Muestra 015[cite: 6]
        when others => d2 <= x"30"; d1 <= x"30"; d0 <= x"30"; -- Otros valores → Muestra 000[cite: 6]
      end case;
    end if;
  end process;

  -- MÁQUINA DE ESTADOS PRINCIPAL
  process(clk_lento, rst_n)
  begin
    if rst_n = '0' then
      estado_actual <= LEER_ROM; -- Regresa al estado inicial de lectura[cite: 6]
      indice <= 0;               -- Reinicia el índice de dirección[cite: 6]
      ram_we <= '0';             -- Desactiva escritura en RAM[cite: 6]
    elsif rising_edge(clk_lento) then
      case estado_actual is
        when LEER_ROM =>
          ram_we <= '0'; -- Prepara lectura de ROM[cite: 6]
          estado_actual <= ESCRIBIR_RAM;
        when ESCRIBIR_RAM =>
          ram_din <= rom_data; -- Pasa dato de ROM a RAM[cite: 6]
          ram_we  <= '1';      -- Habilita escritura[cite: 6]
          estado_actual <= LEER_RAM;
        when LEER_RAM =>
          ram_we <= '0'; -- Habilita lectura de lo guardado[cite: 6]
          estado_actual <= MOSTRAR;
        when MOSTRAR =>
          estado_actual <= BORRAR_RAM; -- Estado de visualización[cite: 6]
        when BORRAR_RAM =>
          ram_din <= x"00"; -- Limpia la celda actual[cite: 6]
          ram_we  <= '1';   
          if indice = 3 then indice <= 0; else indice <= indice + 1; end if; -- Incrementa índice[cite: 6]
          estado_actual <= LEER_ROM;
      end case;
    end if;
  end process;
end architecture;