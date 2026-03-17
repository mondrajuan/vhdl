library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar señales digitales como std_logic
-- ENTIDAD (Define las entradas y salidas del divisor de frecuencia)
entity contadorvhl is -- Nombre del módulo divisor de frecuencia
    port (
        clk       : in  std_logic; -- Reloj principal de la FPGA
        freq_sel  : in  std_logic_vector(1 downto 0); -- Selector de frecuencia de salida
        clk_out   : out std_logic -- Reloj de salida dividido
    );
end entity contadorvhl; -- Fin de la entidad
-- ARQUITECTURA (Define el funcionamiento interno del divisor)
architecture pro of contadorvhl is
-- SEÑALES INTERNAS
signal contador : integer := 0; -- Contador que cuenta los ciclos del reloj principal
signal divisor  : integer := 50000000; -- Valor máximo que determina la división de frecuencia
signal salida   : std_logic := '0'; -- Señal de salida que generará el nuevo reloj
begin -- Inicio de la arquitectura
-- SELECCIÓN DEL DIVISOR SEGÚN freq_sel
divisor <= 50000000 when freq_sel = "00" else -- Divide el reloj para obtener la frecuencia más baja
           25000000 when freq_sel = "01" else -- Frecuencia un poco mayor
           12500000 when freq_sel = "10" else -- Frecuencia aún mayor
           6250000; -- Frecuencia más alta disponible en este módulo
-- PROCESO PRINCIPAL DEL DIVISOR DE FRECUENCIA
process(clk) -- El proceso se ejecuta en cada cambio del reloj principal
begin
    if rising_edge(clk) then -- En cada flanco ascendente del reloj
        -- COMPARACIÓN DEL CONTADOR CON EL DIVISOR
        if contador >= divisor then -- Si el contador alcanza el valor del divisor
            contador <= 0; -- El contador se reinicia
            salida <= not salida; -- Se invierte la señal de salida para generar el nuevo reloj
        else
            contador <= contador + 1; -- Si no ha llegado al divisor, sigue contando
        end if;
    end if;
end process;
-- ASIGNACIÓN DE LA SALIDA DEL RELOJ DIVIDIDO
clk_out <= salida; -- La salida del módulo es la señal dividida
end architecture pro; -- Fin de la arquitectura