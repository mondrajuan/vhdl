library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic

-- PAQUETE DE MEMORIA (Agrupa todas las declaraciones compartidas del proyecto)
-- Este paquete actúa como un "diccionario" que los demás archivos consultan
-- para conocer las interfaces de cada componente sin necesidad de leer su código interno
package mem_pkg is

  -- CONSTANTES GLOBALES DEL BUS
  -- Al cambiarlas aquí, se actualizan automáticamente en todos los componentes
  constant DATA_WIDTH : positive := 8; -- Ancho del bus de datos: 8 bits (1 byte por celda)
  constant ADDR_WIDTH : positive := 4; -- Ancho del bus de dirección: 4 bits = 16 posiciones de memoria

  -- DECLARACIÓN DE COMPONENTE 1: ROM SÍNCRONA (Archivo rom_sync.vhd)
  -- Memoria de solo lectura que contiene los datos grabados en fábrica
  -- Este componente NO se debe modificar internamente
  component rom_sync is
    generic (
      DATA_WIDTH : positive := 8; -- Ancho de dato configurable (por defecto 8 bits)
      ADDR_WIDTH : positive := 4  -- Ancho de dirección configurable (por defecto 4 bits → 16 celdas)
    );
    port (
      clk      : in  std_logic;                            -- Reloj: sincroniza la lectura
      addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Dirección de la celda a leer
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)   -- Dato leído de esa dirección
    );
  end component; -- Fin de la declaración de rom_sync

  -- DECLARACIÓN DE COMPONENTE 2: RAM SÍNCRONA (Archivo ram_sincrona.vhd)
  -- Memoria de lectura y escritura que almacena datos temporalmente
  -- Este componente NO se debe modificar internamente
  component ram_sincrona is
    generic (
      DATA_WIDTH : positive := 8;              -- Ancho de dato configurable (por defecto 8 bits)
      ADDR_WIDTH : positive := 4;              -- Ancho de dirección configurable (por defecto 4 bits)
      RDW_MODE   : string   := "READ_FIRST"    -- Modo de lectura/escritura simultánea
                                               -- "READ_FIRST"  → devuelve el dato anterior al escribir
                                               -- "WRITE_FIRST" → devuelve el dato recién escrito
                                               -- "NO_CHANGE"   → la salida no cambia al escribir
    );
    port (
      clk      : in  std_logic;                            -- Reloj: sincroniza lecturas y escrituras
      rd_en    : in  std_logic;                            -- Habilitador de lectura (1=leer, 0=no leer)
      wr_en    : in  std_logic;                            -- Habilitador de escritura (1=escribir, 0=no escribir)
      addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Dirección de la celda a acceder
      data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);  -- Dato a escribir en la celda
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)   -- Dato leído de la celda
    );
  end component; -- Fin de la declaración de ram_sincrona

  -- DECLARACIÓN DE COMPONENTE 3: DECODIFICADOR 7 SEGMENTOS (Archivo dec7seg.vhd)
  -- Convierte un código ASCII numérico en las señales para encender el display físico
  -- Recibe 8 bits (código ASCII) y entrega 7 bits (uno por cada segmento del display)
  component dec7seg is
    port(
      char : in  std_logic_vector(7 downto 0); -- Entrada: código ASCII del dígito a mostrar
      seg  : out std_logic_vector(6 downto 0)  -- Salida: señales para los 7 segmentos (ánodo común)
    );
  end component; -- Fin de la declaración de dec7seg

  -- DECLARACIÓN DE COMPONENTE 4: DIVISOR DE FRECUENCIA (Archivo contadorvhl.vhd)
  -- Divide el reloj de 50 MHz de la FPGA a frecuencias más lentas y visibles
  -- Este componente NO se debe modificar internamente
  component contadorvhl is
    port (
      clk       : in  std_logic;                       -- Reloj principal de la FPGA (50 MHz)
      freq_sel  : in  std_logic_vector(1 downto 0);    -- Selector: 00=1Hz, 01=2Hz, 10=4Hz, 11=8Hz
      clk_out   : out std_logic                        -- Reloj de salida ya dividido
    );
  end component; -- Fin de la declaración de contadorvhl

end package mem_pkg; -- Fin del paquete de memoria