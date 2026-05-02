library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales como std_logic
-- ENTIDAD (Define las entradas y salidas del decodificador de 7 segmentos)
entity dec7seg is -- Nombre del módulo decodificador
  port(
    char : in  std_logic_vector(7 downto 0); -- Entrada: código ASCII del dígito (8 bits)
    seg  : out std_logic_vector(6 downto 0)  -- Salida: 7 segmentos del display (a,b,c,d,e,f,g)
  );
end entity; -- Fin de la entidad
-- ARQUITECTURA (Define el funcionamiento interno del decodificador)
architecture rtl of dec7seg is
begin -- Inicio de la arquitectura

  -- PROCESO DE DECODIFICACIÓN
  -- Se activa cada vez que cambia la señal 'char'
  process(char) -- El proceso es sensible a la entrada char
  begin
    -- TABLA DE CONVERSIÓN ASCII → SEGMENTOS
    -- Cada bit del vector de salida controla un segmento del display
    -- El orden es: seg(6)=g, seg(5)=f, seg(4)=e, seg(3)=d, seg(2)=c, seg(1)=b, seg(0)=a
    -- IMPORTANTE: Los displays de la DE1 son de ánodo común (0=encendido, 1=apagado)
    case char is
      when x"30" => seg <= "1000000"; -- ASCII '0' (0x30) → muestra el dígito 0 en el display
      when x"31" => seg <= "1111001"; -- ASCII '1' (0x31) → muestra el dígito 1 en el display
      when x"32" => seg <= "0100100"; -- ASCII '2' (0x32) → muestra el dígito 2 en el display
      when x"33" => seg <= "0110000"; -- ASCII '3' (0x33) → muestra el dígito 3 en el display
      when x"34" => seg <= "0011001"; -- ASCII '4' (0x34) → muestra el dígito 4 en el display
      when x"35" => seg <= "0010010"; -- ASCII '5' (0x35) → muestra el dígito 5 en el display
      when x"36" => seg <= "0000010"; -- ASCII '6' (0x36) → muestra el dígito 6 en el display
      when x"37" => seg <= "1111000"; -- ASCII '7' (0x37) → muestra el dígito 7 en el display
      when x"38" => seg <= "0000000"; -- ASCII '8' (0x38) → enciende todos los segmentos
      when x"39" => seg <= "0010000"; -- ASCII '9' (0x39) → muestra el dígito 9 en el display
      when others => seg <= "1111111"; -- Cualquier otro valor → apaga todos los segmentos
    end case;
  end process; -- Fin del proceso de decodificación
end architecture; -- Fin de la arquitectura