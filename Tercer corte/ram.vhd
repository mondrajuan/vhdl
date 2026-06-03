library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite definir vectores binarios std_logic_vector
use ieee.numeric_std.all; -- Habilita indexaciones de matrices convirtiendo direcciones binarias a enteros

-- ENTIDAD DE LA MEMORIA RAM (Memoria de lectura y escritura de datos intermedios)
entity ram is
  port (
    clk   : in std_logic;                    -- Reloj de sistema para escrituras síncronas estables
    rst   : in std_logic;                    -- Reset general asíncrono para vaciar/limpiar la memoria completa
    addr  : in std_logic_vector(7 downto 0); -- Bus de direcciones de 8 bits (Permite acceder a 256 posiciones de memoria)
    din   : in std_logic_vector(7 downto 0); -- Bus de entrada con el dato binario que se va a almacenar
    wen   : in std_logic;                    -- Habilitador de escritura (Write Enable: 1 = Guardar, 0 = Solo Leer)
    dout  : out std_logic_vector(7 downto 0) -- Bus de salida que expone el dato almacenado en la dirección addr
  );
end entity ram;

-- ARQUITECTURA (Define el bloque de memoria física y su modo de direccionamiento)
architecture rtl of ram is
  -- Matriz de 256 celdas de almacenamiento con un tamaño de 8 bits cada una
  type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
  signal ram_data : ram_type; -- Señal interna de tipo matriz que simula las celdas de hardware de la RAM
begin
  -- Proceso síncrono encargado de capturar y guardar datos de forma segura
  process(clk, rst)
  begin
    if rst = '1' then -- Si el reset maestro es presionado
      ram_data <= (others => (others => '0')); -- Sobreescribe absolutamente toda la RAM con ceros
    elsif rising_edge(clk) then -- Flanco de subida de reloj
      if wen = '1' then -- Si el Write Enable está activo
        ram_data(to_integer(unsigned(addr))) <= din; -- Convierte la dirección addr a entero y escribe el dato din
      end if;
    end if;
  end process;
  
  -- LECTURA CONTINUA ASÍNCRONA: Devuelve instantáneamente el dato indexado por la dirección addr
  dout <= ram_data(to_integer(unsigned(addr)));
end architecture rtl;
