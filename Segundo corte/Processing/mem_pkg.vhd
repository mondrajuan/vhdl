library ieee;
use ieee.std_logic_1164.all;

package mem_pkg is

  constant DATA_WIDTH : positive := 8;
  constant ADDR_WIDTH : positive := 4;

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

  component dec7seg is
    port(
      char : in  std_logic_vector(7 downto 0);
      seg  : out std_logic_vector(6 downto 0)
    );
  end component;

  component divisor_1Hz is
    port(
      clk50 : in  std_logic;
      clk1  : out std_logic
    );
  end component;

end package mem_pkg;