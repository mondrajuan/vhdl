library ieee;
use ieee.std_logic_1164.all;

package mem_pkg is

  -- Constantes globales para facilitar cambios de bus en el futuro
  constant DATA_WIDTH : positive := 8;
  constant ADDR_WIDTH : positive := 4;

  -- 1. Componente ROM (Archivo rom_sync.vhd)
  -- Este componente no se debe modificar internamente.
  component rom_sync is
    generic (
      DATA_WIDTH : positive := 8;
      ADDR_WIDTH : positive := 4
    );
    port (
      clk      : in  std_logic;
      addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  -- 2. Componente RAM (Archivo ram_sincrona.vhd)
  -- Este componente no se debe modificar internamente.
  component ram_sincrona is
    generic (
      DATA_WIDTH : positive := 8;
      ADDR_WIDTH : positive := 4;
      RDW_MODE   : string   := "READ_FIRST"
    );
    port (
      clk      : in  std_logic;
      rd_en    : in  std_logic;
      wr_en    : in  std_logic;
      addr     : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      data_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  -- 3. Componente Decodificador de 7 Segmentos (Archivo dec7seg.vhd)
  -- Ajustado para recibir el bus de 8 bits (Código ASCII numérico)
  component dec7seg is
    port(
      char : in  std_logic_vector(7 downto 0);
      seg  : out std_logic_vector(6 downto 0)
    );
  end component;

  -- 4. Componente Divisor de Frecuencia (Archivo contadorvhl.vhd)
  -- Este componente no se debe modificar internamente.
  component contadorvhl is
    port (
      clk       : in  std_logic;
      freq_sel  : in  std_logic_vector(1 downto 0);
      clk_out   : out std_logic
    );
  end component;

end package mem_pkg;