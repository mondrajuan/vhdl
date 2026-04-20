library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar señales digitales como std_logic
use IEEE.NUMERIC_STD.ALL; -- Permite hacer conversiones y operaciones matemáticas
-- ENTIDAD (Define las entradas y salidas del contador)
entity contador7seg is
    port(
        clkE   : in std_logic; -- Reloj que controla el incremento del contador
        reset  : in std_logic; -- Señal de reset para reiniciar el contador
        seguni : out std_logic_vector(3 downto 0); -- Salida BCD para las unidades de segundos
        segdec : out std_logic_vector(3 downto 0); -- Salida BCD para las decenas de segundos
        min    : out std_logic_vector(3 downto 0)  -- Salida BCD para los minutos
    );
end entity; -- Fin de la entidad
-- ARQUITECTURA (Aquí se define el funcionamiento interno del contador)
architecture pro of contador7seg is
-- SEÑALES INTERNAS (Variables que guardan los valores del contador)
signal segun : integer range 0 to 9 := 0; -- Guarda las unidades de segundo (0-9)
signal segde : integer range 0 to 5 := 0; -- Guarda las decenas de segundo (0-5)
signal m     : integer range 0 to 9 := 0; -- Guarda los minutos (0-9)
begin -- Inicio de la arquitectura
process(clkE, reset) -- Proceso principal que controla el contador
begin
-- RESET DEL CONTADOR
if reset = '0' then -- Si se activa el reset
    segun <= 0; -- Reinicia las unidades de segundo
    segde <= 0; -- Reinicia las decenas de segundo
    m <= 0; -- Reinicia los minutos
-- FUNCIONAMIENTO NORMAL DEL CONTADOR
elsif rising_edge(clkE) then -- En cada flanco positivo del reloj
    -- CONTADOR DE UNIDADES DE SEGUNDO
    if segun = 9 then -- Si las unidades llegan a 9
        segun <= 0; -- Se reinician las unidades
        -- CONTADOR DE DECENAS DE SEGUNDO
        if segde = 5 then -- Si las decenas llegan a 5 (máximo 59 segundos)
            segde <= 0; -- Se reinician las decenas
            -- CONTADOR DE MINUTOS
            if m = 9 then -- Si los minutos llegan a 9
                m <= 0; -- Se reinician los minutos
            else
                m <= m + 1; -- Incrementa los minutos en 1
            end if;
        else
            segde <= segde + 1; -- Incrementa las decenas de segundo
        end if;
    else
        segun <= segun + 1; -- Incrementa las unidades de segundo
    end if;
end if;
end process; -- Fin del proceso principal
-- CONVERSIÓN DE ENTEROS A VECTOR BCD PARA LOS DISPLAYS
seguni <= std_logic_vector(to_unsigned(segun,4)); -- Convierte unidades a BCD de 4 bits
segdec <= std_logic_vector(to_unsigned(segde,4)); -- Convierte decenas a BCD de 4 bits
min <= std_logic_vector(to_unsigned(m,4)); -- Convierte minutos a BCD de 4 bits
end pro; -- Fin de la arquitectura