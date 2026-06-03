library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales estándar (std_logic y std_logic_vector)
use ieee.numeric_std.all; -- Permite realizar operaciones aritméticas convirtiendo vectores a tipos con/sin signo

-- ENTIDAD DE LA ALU (Define las entradas de datos, control y la salida del resultado)
entity alu is
  port (
    operand_a : in  std_logic_vector(7 downto 0); -- Primer operando de entrada de 8 bits
    operand_b : in  std_logic_vector(7 downto 0); -- Segundo operando de entrada de 8 bits
    opcode    : in  std_logic_vector(2 downto 0); -- Código de operación de 3 bits para seleccionar la función
    result    : out std_logic_vector(7 downto 0)  -- Bus de salida de 8 bits con el resultado final
  );
end entity alu;

-- ARQUITECTURA (Define el comportamiento combinacional de la unidad aritmético-lógica)
architecture behave of alu is
begin
  -- Proceso combinacional sensible a los operandos y al código de operación
  process(operand_a, operand_b, opcode)
  begin
    -- Evalúa el opcode para determinar la operación matemática o lógica a realizar
    case opcode is
      when "000" =>   -- Operación: SUMA
        result <= std_logic_vector(unsigned(operand_a) + unsigned(operand_b)); -- Convierte a sin signo, suma y vuelve a vector
      when "001" =>   -- Operación: RESTA
        result <= std_logic_vector(unsigned(operand_a) - unsigned(operand_b)); -- Convierte a sin signo, resta y vuelve a vector
      when "010" =>   -- Operación: AND LÓGICA
        result <= operand_a and operand_b; -- Realiza la conjunción bit a bit entre ambos operandos
      when "011" =>   -- Operación: OR LÓGICA
        result <= operand_a or operand_b; -- Realiza la disyunción bit a bit entre ambos operandos
      when "100" =>   -- Operación: NOT LÓGICA
        result <= not operand_a; -- Invierte todos los bits del operando A
      when others =>  -- Caso por defecto para cubrir cualquier otra combinación imprevista
        result <= (others => '0'); -- Fuerza la salida completa a ceros lógicos
    end case;
  end process;
end architecture behave;
