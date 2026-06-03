library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite trabajar con lógica digital discreta
use ieee.numeric_std.all; -- Permite tratar vectores como números para contadores e incrementos

-- ENTIDAD DEL PROGRAM COUNTER (PC - Lleva el control de la dirección de memoria que se ejecutará)
entity program_counter is
  port (
    clk     : in std_logic;                    -- Reloj del sistema para control síncrono de la cuenta
    rst     : in std_logic;                    -- Reset general asíncrono para retornar al inicio del programa
    pc_inc  : in std_logic;                    -- Entrada de control para incrementar secuencialmente la dirección (+1)
    pc_load : in std_logic;                    -- Entrada de control para realizar saltos cargando un valor externo
    data_in : in std_logic_vector(7 downto 0); -- Dirección destino en caso de ocurrir una instrucción de salto (JMP)
    pc_out  : out std_logic_vector(7 downto 0) -- Dirección actual de salida conectada directamente a la ROM
  );
end entity program_counter;

-- ARQUITECTURA (Lógica secuencial con prioridades para el control del registro del PC)
architecture rtl of program_counter is
  signal pc_value : std_logic_vector(7 downto 0); -- Señal interna de 8 bits que retiene el valor actual del contador
begin
  -- Proceso síncrono encargado de administrar el flujo del contador
  process(clk, rst)
  begin
    if rst = '1' then -- Si se activa el reset
      pc_value <= (others => '0'); -- Reinicia la cuenta regresando a la dirección de memoria x"00"
    elsif rising_edge(clk) then -- Flanco de subida de reloj
      if pc_load = '1' then -- PRIORIDAD 1: Si se ordena un salto incondicional (JUMP)
        pc_value <= data_in; -- El PC absorbe y se sitúa en la dirección recibida por data_in
      elsif pc_inc = '1' then -- PRIORIDAD 2: Si se ordena un avance secuencial normal
        pc_value <= std_logic_vector(unsigned(pc_value) + 1); -- Pasa a sin signo, incrementa en uno y lo reconvierte
      end if;
    end if;
  end process;
  
  pc_out <= pc_value; -- Envía de manera ininterrumpida la dirección actual hacia la ROM
end architecture rtl;
