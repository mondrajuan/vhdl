library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_pkg.all;

entity ROMRAM is
  port(
    CLOCK_50 : in  std_logic;
    rst      : in  std_logic;
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of ROMRAM is
  signal clk1      : std_logic;
  signal base      : std_logic_vector(3 downto 0);
  signal base_p1   : std_logic_vector(3 downto 0);
  signal base_p2   : std_logic_vector(3 downto 0);
  signal lfsr      : std_logic_vector(3 downto 0);
  signal lfsr_next : std_logic_vector(3 downto 0);
  signal d0, d1, d2 : std_logic_vector(7 downto 0);

begin
  
  u_div : divisor_1Hz
    port map(
      clk50 => CLOCK_50,
      clk1  => clk1
    );

  
  lfsr_next <= lfsr(2 downto 0) & (lfsr(3) xor lfsr(2));
  
  process(clk1, rst)
  begin
    if rst = '1' then
      lfsr <= "1011";
    elsif rising_edge(clk1) then
      lfsr <= lfsr_next;
    end if;
  end process;

  
  base   <= lfsr(3 downto 2) & "00";
  base_p1 <= std_logic_vector(unsigned(base) + 1);
  base_p2 <= std_logic_vector(unsigned(base) + 2);

  
  u_rom0 : rom_sync
    generic map(DATA_WIDTH => 8, ADDR_WIDTH => 4)
    port map(
      clk      => clk1,
      addr     => base,
      data_out => d0
    );

  u_rom1 : rom_sync
    generic map(DATA_WIDTH => 8, ADDR_WIDTH => 4)
    port map(
      clk      => clk1,
      addr     => base_p1,
      data_out => d1
    );

  u_rom2 : rom_sync
    generic map(DATA_WIDTH => 8, ADDR_WIDTH => 4)
    port map(
      clk      => clk1,
      addr     => base_p2,
      data_out => d2
    );

  -- Decodificadores 7 segmentos
  u0: dec7seg port map(char => d0, seg => HEX0);
  u1: dec7seg port map(char => d1, seg => HEX1);
  u2: dec7seg port map(char => d2, seg => HEX2);

end architecture;