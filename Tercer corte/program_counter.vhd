library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity program_counter is
  port (
    clk     : in std_logic;
    rst     : in std_logic;
    pc_inc  : in std_logic;
    pc_load : in std_logic;
    data_in : in std_logic_vector(7 downto 0);
    pc_out  : out std_logic_vector(7 downto 0)
  );
end entity program_counter;

architecture rtl of program_counter is
  signal pc_value : std_logic_vector(7 downto 0);
begin
  process(clk, rst)
  begin
    if rst = '1' then
      pc_value <= (others => '0');
    elsif rising_edge(clk) then
      if pc_load = '1' then
        pc_value <= data_in;
      elsif pc_inc = '1' then
        pc_value <= std_logic_vector(unsigned(pc_value) + 1);
      end if;
    end if;
  end process;
  pc_out <= pc_value;
end architecture rtl;