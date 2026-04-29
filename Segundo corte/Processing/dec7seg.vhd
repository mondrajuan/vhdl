library ieee;
use ieee.std_logic_1164.all;

entity dec7seg is
  port(
    char : in  std_logic_vector(7 downto 0);
    seg  : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of dec7seg is
begin
  process(char)
  begin
    case char is
      -- Dígitos del 0 al 9 (ASCII x"30" a x"39")
      when x"30" => seg <= "0111111";  -- 0
      when x"31" => seg <= "0000110";  -- 1
      when x"32" => seg <= "1011011";  -- 2
      when x"33" => seg <= "1001111";  -- 3
      when x"34" => seg <= "1100110";  -- 4
      when x"35" => seg <= "1101101";  -- 5
      when x"36" => seg <= "1111101";  -- 6
      when x"37" => seg <= "0000111";  -- 7
      when x"38" => seg <= "1111111";  -- 8
      when x"39" => seg <= "1101111";  -- 9
      when others => seg <= "0000000";  -- Apagado
    end case;
  end process;

end architecture;