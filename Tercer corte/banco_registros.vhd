library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite trabajar con niveles lógicos estándar
use ieee.numeric_std.all; -- Habilita conversiones numéricas como to_integer y unsigned

-- ENTIDAD DEL BANCO DE REGISTROS (Almacenamiento temporal interno del procesador)
entity banco_registros is
  port (
    clk      : in std_logic;                     -- Reloj maestro del sistema para sincronización síncrona
    rst      : in std_logic;                     -- Señal de reset asíncrono para inicializar registros
    addr_w   : in std_logic_vector(1 downto 0);  -- Dirección del registro donde se desea ESCRIBIR (4 registros posibles)
    addr_r1  : in std_logic_vector(1 downto 0);  -- Dirección del primer registro que se desea LEER
    addr_r2  : in std_logic_vector(1 downto 0);  -- Dirección del segundo registro que se desea LEER
    din      : in std_logic_vector(7 downto 0);  -- Bus de datos de entrada con el valor a escribir
    wen      : in std_logic;                     -- Habilitador de escritura (1 = Habilitado, 0 = Solo lectura)
    dout1    : out std_logic_vector(7 downto 0); -- Bus de salida con el contenido del registro indexado por addr_r1
    dout2    : out std_logic_vector(7 downto 0)  -- Bus de salida con el contenido del registro indexado por addr_r2
  );
end entity banco_registros;

-- ARQUITECTURA (Define la matriz de memoria interna y su comportamiento de transferencia)
architecture rtl of banco_registros is
  -- Matriz de 4 filas por 8 bits cada una para representar los registros R0, R1, R2 y R3
  type reg_array is array (0 to 3) of std_logic_vector(7 downto 0);
  signal regs : reg_array; -- Señal interna de tipo matriz que aloja los datos físicos
begin
  -- Proceso secuencial para el control de la escritura y el reset
  process(clk, rst)
  begin
    if rst = '1' then -- Si el reset se encuentra activo (lógica directa)
      regs <= (others => (others => '0')); -- Llena todas las posiciones de todos los registros con ceros
    elsif rising_edge(clk) then -- Sincronización en el flanco de subida del reloj
      if wen = '1' then -- Si la habilitación de escritura está encendida
        regs(to_integer(unsigned(addr_w))) <= din; -- Convierte la dirección a entero y guarda el dato de entrada
      end if;
    end if;
  end process;
  
  -- LECTURA ASÍNCRONA: Las salidas reflejan inmediatamente los cambios en las direcciones de lectura
  dout1 <= regs(to_integer(unsigned(addr_r1))); -- Muestra de forma continua el contenido del registro 1 seleccionado
  dout2 <= regs(to_integer(unsigned(addr_r2))); -- Muestra de forma continua el contenido del registro 2 seleccionado
end architecture rtl;
