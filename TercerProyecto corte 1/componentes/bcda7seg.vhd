library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar señales digitales como std_logic

-- ENTIDAD (Define las entradas y salidas del componente)

entity bcda7seg is -- Nombre del módulo que convierte BCD a display de 7 segmentos
    port (
        A: in  std_logic_vector(3 downto 0);   -- Entrada BCD de 4 bits (número del 0 al 9)
        D: out std_logic_vector(6 downto 0)    -- Salida hacia el display de 7 segmentos
    );
end entity bcda7seg; -- Fin de la entidad

-- ARQUITECTURA (Aquí se define cómo funciona el conversor)

architecture pro of bcda7seg is -- Nombre de la arquitectura
begin -- Inicio de la arquitectura
    process (A) -- Proceso que se ejecuta cada vez que cambia la entrada A
    begin
        case A is -- Se evalúa el valor del número BCD recibido
            when "0000" => D <= "1000000"; -- Si A = 0 se muestran los segmentos del número 0
            when "0001" => D <= "1111001"; -- Si A = 1 se muestran los segmentos del número 1
            when "0010" => D <= "0100100"; -- Si A = 2 se muestran los segmentos del número 2
            when "0011" => D <= "0110000"; -- Si A = 3 se muestran los segmentos del número 3
            when "0100" => D <= "0011001"; -- Si A = 4 se muestran los segmentos del número 4
            when "0101" => D <= "0010010"; -- Si A = 5 se muestran los segmentos del número 5
            when "0110" => D <= "0000010"; -- Si A = 6 se muestran los segmentos del número 6
            when "0111" => D <= "1111000"; -- Si A = 7 se muestran los segmentos del número 7
            when "1000" => D <= "0000000"; -- Si A = 8 se muestran los segmentos del número 8
            when "1001" => D <= "0010000"; -- Si A = 9 se muestran los segmentos del número 9
            when others => D <= "1111111"; -- Si llega un valor diferente se apagan todos los segmentos
        end case; -- Fin del case
    end process; -- Fin del proceso
end pro; -- Fin de la arquitectura