library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Habilita tipos estándar de señales digitales
use ieee.numeric_std.all; -- Permite usar direccionamiento numérico convirtiendo vectores a enteros

-- ENTIDAD DE LA MEMORIA ROM (Memoria de solo lectura que almacena de forma fija el código del programa)
entity rom is
  port (
    addr : in  std_logic_vector(7 downto 0); -- Bus de direcciones de 8 bits proveniente directamente del Program Counter
    dout : out std_logic_vector(7 downto 0)  -- Bus de salida que entrega la instrucción o dato almacenado en esa posición
  );
end entity rom;

-- ARQUITECTURA (Contiene los datos del software pre-grabado y define la lectura del código)
architecture behave of rom is
  -- Matriz constante de 256 espacios de 8 bits para alojar el firmware del sistema
  type rom_type is array (0 to 255) of std_logic_vector(7 downto 0);
  -- Inicialización directa de la ROM con instrucciones específicas y sus operandos correspondientes
  signal rom_data : rom_type := (
    0 => x"01", -- Instrucción: LD (Cargar al registro R0)
    1 => x"FF", -- Operando: Dirección x"FF" (Representa el puerto de lectura físico ENTRADA)
    2 => x"02", -- Instrucción: ST (Guardar contenido de R0)
    3 => x"10", -- Operando: Dirección x"10" (Dirección destino interna en la RAM)
    4 => x"01", -- Instrucción: LD (Cargar al registro R0)
    5 => x"10", -- Operando: Desde la RAM dirección x"10"
    6 => x"00", -- Instrucción: AND R0, R0 (Usa la ALU para realizar un paso y refrescar banderas/datos)
    7 => x"02", -- Instrucción: ST (Guardar el resultado procesado)
    8 => x"11", -- Operando: Dirección x"11" de la memoria RAM
    9 => x"01", -- Instrucción: LD (Cargar al registro R0)
   10 => x"11", -- Operando: Trae el dato nuevo de la RAM en la dirección x"11"
   11 => x"02", -- Instrucción: ST (Guardar de salida)
   12 => x"FE", -- Operando: Dirección x"FE" (Mapeada físicamente a los Leds y al Ventilador de SALIDA)
   13 => x"08", -- Instrucción: JMP (Salto incondicional para generar un bucle infinito)
   14 => x"00", -- Operando: Dirección x"00" (Regresa al inicio de todo el programa)
   others => x"00" -- Llena el resto de la memoria ROM no utilizada con ceros lógicos
  );
begin
  -- LECTURA PURAMENTE COMBINACIONAL: Al cambiar la dirección addr, el dato sale inmediatamente
  dout <= rom_data(to_integer(unsigned(addr)));
end architecture behave;
