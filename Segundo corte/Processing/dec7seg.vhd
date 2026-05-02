library ieee;
use ieee.std_logic_1164.all;

entity dec7seg is
  port(
    char : in  std_logic_vector(7 downto 0); -- Recibe el código ASCII del número
    seg  : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of dec7seg is
begin
  process(char)
  begin
    case char is
      -- Solo reconoce los caracteres ASCII del '0' al '9'
      when x"30" => seg <= "1000000"; -- 0
      when x"31" => seg <= "1111001"; -- 1
      when x"32" => seg <= "0100100"; -- 2
      when x"33" => seg <= "0110000"; -- 3
      when x"34" => seg <= "0011001"; -- 4
      when x"35" => seg <= "0010010"; -- 5
      when x"36" => seg <= "0000010"; -- 6
      when x"37" => seg <= "1111000"; -- 7
      when x"38" => seg <= "0000000"; -- 8
      when x"39" => seg <= "0010000"; -- 9
      when others => seg <= "1111111"; -- Apagado si no es número
    end case;
  end process;
end architecture;