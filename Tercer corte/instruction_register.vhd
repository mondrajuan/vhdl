library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales digitales estándar

-- ENTIDAD DEL REGISTRO DE INSTRUCCIÓN (IR - Guarda temporalmente el código de la operación actual)
entity instruction_register is
  port (
    clk   : in std_logic;                    -- Reloj de sistema para escritura síncrona
    rst   : in std_logic;                    -- Reset asíncrono para limpiar la instrucción
    en    : in std_logic;                    -- Señal de habilitación de escritura generada por la unidad de control
    din   : in std_logic_vector(7 downto 0); -- Bus de entrada de 8 bits con la instrucción leída de la ROM
    dout  : out std_logic_vector(7 downto 0) -- Bus de salida que expone permanentemente la instrucción cargada
  );
end entity instruction_register;

-- ARQUITECTURA (Define la lógica interna del registro)
architecture rtl of instruction_register is
  signal instr : std_logic_vector(7 downto 0); -- Señal interna tipo registro para retener el dato físico
begin
  -- Proceso síncrono por flanco con borrado asíncrono
  process(clk, rst)
  begin
    if rst = '1' then -- Si el reset está activado
      instr <= (others => '0'); -- Borra el registro completo asignándole ceros
    elsif rising_edge(clk) then -- Flanco ascendente de reloj
      if en = '1' then -- Si la unidad de control da el permiso de habilitación
        instr <= din; -- Almacena y retiene el dato del bus de entrada din
      end if;
    end if;
  end process;
  
  dout <= instr; -- Envía de forma continua la instrucción retenida hacia la salida dout
end architecture rtl;
