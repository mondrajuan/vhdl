library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  port (
    operand_a : in  std_logic_vector(7 downto 0);
    operand_b : in  std_logic_vector(7 downto 0);
    opcode    : in  std_logic_vector(2 downto 0);
    result    : out std_logic_vector(7 downto 0)
  );
end entity alu;

architecture behave of alu is
begin
  process(operand_a, operand_b, opcode)
  begin
    case opcode is
      when "000" =>   
        result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b));
      when "001" =>   
        result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b));
      when "010" =>   
        result <= operand_a and operand_b;
      when "011" =>   
        result <= operand_a or operand_b;
      when "100" =>   
        result <= not operand_a;
      when others =>
        result <= (others => '0');
    end case;
  end process;
end architecture behave;