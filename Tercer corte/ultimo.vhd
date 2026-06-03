library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Permite usar señales lógicas estándar en todo el hardware interno
use ieee.numeric_std.all; -- Habilita operaciones de comparación y adición con números sin signo

entity ultimo is -- Inicia la declaración de la entidad principal (Top Level)
  port ( -- Define los puertos de entrada y salida físicos
    clk            : in  std_logic; -- Señal de reloj maestro proveniente de la FPGA
    switches       : in  std_logic_vector(2 downto 0); -- Bus de 3 bits para los interruptores físicos
    led_out        : out std_logic; -- Salida digital para controlar el encendido de un LED
    ventilador_out : out std_logic -- Salida digital para controlar el actuador del ventilador
  ); -- Cierra la declaración de la lista de puertos
end entity ultimo; -- Finaliza la entidad principal

architecture behave of ultimo is -- Inicia la arquitectura estructural del procesador

  component program_counter -- Declaración del componente Program Counter
    port ( -- Puertos del Program Counter
      clk     : in  std_logic; -- Reloj del sistema
      rst     : in  std_logic; -- Reset asíncrono
      pc_inc  : in  std_logic; -- Habilitador de incremento secuencial
      pc_load : in  std_logic; -- Habilitador de carga para saltos
      data_in : in  std_logic_vector(7 downto 0); -- Bus de entrada para la dirección de salto
      pc_out  : out std_logic_vector(7 downto 0) -- Bus de salida con la dirección actual
    ); -- Cierra los puertos del PC
  end component; -- Finaliza la declaración del componente PC

  component instruction_register -- Declaración del componente Registro de Instrucción
    port ( -- Puertos del IR
      clk  : in  std_logic; -- Reloj del sistema
      rst  : in  std_logic; -- Reset asíncrono
      en   : in  std_logic; -- Habilitador de escritura
      din  : in  std_logic_vector(7 downto 0); -- Bus de entrada de datos
      dout : out std_logic_vector(7 downto 0) -- Bus de salida de la instrucción retenida
    ); -- Cierra los puertos del IR
  end component; -- Finaliza la declaración del componente IR

  component rom -- Declaración de la Memoria ROM
    port ( -- Puertos de la ROM
      addr : in  std_logic_vector(7 downto 0); -- Dirección de memoria a leer
      dout : out std_logic_vector(7 downto 0) -- Dato leído de la dirección
    ); -- Cierra los puertos de la ROM
  end component; -- Finaliza la declaración de la ROM

  component ram -- Declaración de la Memoria RAM
    port ( -- Puertos de la RAM
      clk  : in  std_logic; -- Reloj del sistema
      rst  : in  std_logic; -- Reset para borrar la memoria
      addr : in  std_logic_vector(7 downto 0); -- Dirección a acceder
      din  : in  std_logic_vector(7 downto 0); -- Dato a escribir
      wen  : in  std_logic; -- Habilitador de escritura (Write Enable)
      dout : out std_logic_vector(7 downto 0) -- Dato leído
    ); -- Cierra los puertos de la RAM
  end component; -- Finaliza la declaración de la RAM

  component banco_registros -- Declaración del Banco de Registros
    port ( -- Puertos del Banco de Registros
      clk     : in  std_logic; -- Reloj del sistema
      rst     : in  std_logic; -- Reset para limpiar registros
      addr_w  : in  std_logic_vector(1 downto 0); -- Dirección del registro a escribir
      addr_r1 : in  std_logic_vector(1 downto 0); -- Dirección del registro a leer (Salida 1)
      addr_r2 : in  std_logic_vector(1 downto 0); -- Dirección del registro a leer (Salida 2)
      din     : in  std_logic_vector(7 downto 0); -- Bus de entrada de datos
      wen     : in  std_logic; -- Habilitador de escritura
      dout1   : out std_logic_vector(7 downto 0); -- Bus de salida de datos 1
      dout2   : out std_logic_vector(7 downto 0) -- Bus de salida de datos 2
    ); -- Cierra los puertos del Banco
  end component; -- Finaliza la declaración del Banco de Registros

  component alu -- Declaración de la Unidad Aritmético-Lógica
    port ( -- Puertos de la ALU
      operand_a : in  std_logic_vector(7 downto 0); -- Primer operando
      operand_b : in  std_logic_vector(7 downto 0); -- Segundo operando
      opcode    : in  std_logic_vector(2 downto 0); -- Código de la operación a ejecutar
      result    : out std_logic_vector(7 downto 0) -- Resultado de la operación
    ); -- Cierra los puertos de la ALU
  end component; -- Finaliza la declaración de la ALU

  component control_unit -- Declaración de la Unidad de Control
    port ( -- Puertos de la FSM de Control
      clk     : in  std_logic; -- Reloj del sistema
      rst     : in  std_logic; -- Reset del sistema
      opcode  : in  std_logic_vector(7 downto 0); -- Código de operación desde el IR
      pc_inc  : out std_logic; -- Control: Incremento del PC
      pc_load : out std_logic; -- Control: Carga del PC
      ir_en   : out std_logic; -- Control: Habilitación del IR
      addr_en : out std_logic; -- Control: Captura de dirección
      reg_wen : out std_logic; -- Control: Escritura en registros
      reg_src : out std_logic; -- Control: Selección de origen de datos
      ram_wen : out std_logic; -- Control: Escritura en RAM
      alu_op  : out std_logic_vector(2 downto 0) -- Control: Operación de la ALU
    ); -- Cierra los puertos de Control
  end component; -- Finaliza la declaración de la Unidad de Control

  signal rst_reg     : std_logic_vector(3 downto 0) := (others => '1'); -- Registro de desplazamiento para estabilizar el reset al encender
  signal rst_interno : std_logic; -- Señal de reset filtrada y estable para uso interno
  signal pc_out       : std_logic_vector(7 downto 0); -- Cable que lleva la dirección actual desde el PC hacia la ROM
  signal ir_out       : std_logic_vector(7 downto 0); -- Cable que transporta la instrucción retenida desde el IR
  signal addr_reg     : std_logic_vector(7 downto 0); -- Registro intermedio para guardar direcciones leídas de la ROM
  signal rom_data     : std_logic_vector(7 downto 0); -- Cable con el dato/instrucción cruda entregado por la ROM
  signal ram_data_out : std_logic_vector(7 downto 0); -- Cable con el dato leído desde la RAM
  signal ram_addr     : std_logic_vector(7 downto 0); -- Cable que apunta la dirección a acceder en la RAM
  signal ram_data_in  : std_logic_vector(7 downto 0); -- Cable con el dato que se va a escribir en la RAM
  signal reg_out1     : std_logic_vector(7 downto 0); -- Cable de salida del puerto 1 del Banco de Registros
  signal reg_out2     : std_logic_vector(7 downto 0); -- Cable de salida del puerto 2 del Banco de Registros
  signal reg_din      : std_logic_vector(7 downto 0); -- Cable multiplexado con el dato a guardar en el Banco de Registros
  signal alu_result   : std_logic_vector(7 downto 0); -- Cable que transporta el resultado inmediato de la ALU
  signal bank_addr_w  : std_logic_vector(1 downto 0); -- Cable con la dirección calculada para escribir en el Banco
  signal bank_addr_r1 : std_logic_vector(1 downto 0); -- Cable con la dirección calculada para leer el puerto 1 del Banco

  signal pc_inc  : std_logic; -- Señal de control interna para incrementar el PC
  signal pc_load : std_logic; -- Señal de control interna para cargar salto en el PC
  signal ir_en   : std_logic; -- Señal de control interna para habilitar el IR
  signal addr_en : std_logic; -- Señal de control interna para capturar la dirección
  signal reg_wen : std_logic; -- Señal de control interna para escribir en el banco de registros
  signal reg_src : std_logic; -- Señal de control interna para multiplexar el dato de entrada a registros
  signal ram_wen : std_logic; -- Señal de control interna para habilitar escritura en RAM
  signal alu_op  : std_logic_vector(2 downto 0); -- Señal de control interna para seleccionar la operación de la ALU

  constant ADDR_ENTRADA : std_logic_vector(7 downto 0) := x"FF"; -- Constante que define la dirección del puerto de ENTRADA
  constant ADDR_SALIDA  : std_logic_vector(7 downto 0) := x"FE"; -- Constante que define la dirección del puerto de SALIDA
  constant OPC_LD       : std_logic_vector(7 downto 0) := x"01"; -- Código de la instrucción LOAD (Cargar)
  constant OPC_ST       : std_logic_vector(7 downto 0) := x"02"; -- Código de la instrucción STORE (Guardar)

  signal entrada_data : std_logic_vector(7 downto 0); -- Cable que agrupa y formatea las señales de entrada de los switches
  signal salida_reg   : std_logic_vector(7 downto 0); -- Registro físico que retiene el último estado enviado a las salidas

  signal modo          : std_logic; -- Bit de control que define si estamos en modo manual o automático
  signal switch_led    : std_logic; -- Bit de control que refleja el estado del interruptor del LED
  signal switch_fan    : std_logic; -- Bit de control que refleja el estado del interruptor del ventilador
  
  signal contador_auto : unsigned(27 downto 0); -- Señal de contador grande para generar demoras visibles de tiempo
  signal estado_auto   : std_logic_vector(1 downto 0); -- Banderas lógicas que rotan automáticamente en modo automático
  constant PERIODO_AUTO : unsigned(27 downto 0) := to_unsigned(250000000, 28); -- Constante temporal muy baja para pruebas de simulación

begin -- Inicia el bloque de instrucciones concurrentes

  process(clk) -- Proceso para generar un reset seguro y evitar metaestabilidad al encender
  begin -- Inicio del proceso de reset
    if rising_edge(clk) then -- Sincronizado en el flanco de subida del reloj maestro
      rst_reg <= rst_reg(2 downto 0) & '0'; -- Empuja un '0' en el registro de desplazamiento
    end if; -- Fin de la condición del reloj
  end process; -- Fin del proceso de reset

  rst_interno <= rst_reg(3); -- Se toma el bit más significativo como un reset limpio y estable

  modo       <= switches(2); -- El switch en la posición 2 controla la selección de Modo
  switch_led <= switches(1); -- El switch en la posición 1 controla directamente el LED en modo manual
  switch_fan <= switches(0); -- El switch en la posición 0 controla directamente el ventilador en modo manual

  entrada_data <= "000000" & switch_led & switch_fan when modo = '0' else -- Si el modo es manual ('0'), arma el byte con los switches físicos
                  "000000" & estado_auto; -- De lo contrario (modo automático), arma el byte con el contador automático

  pc_inst : program_counter -- Instancia física del Program Counter
    port map ( -- Mapeo de puertos del PC a señales internas
      clk     => clk, -- Conecta el reloj maestro
      rst     => rst_interno, -- Conecta el reset seguro interno
      pc_inc  => pc_inc, -- Conecta la señal de control de incremento
      pc_load => pc_load, -- Conecta la señal de control de carga
      data_in => addr_reg, -- Conecta el registro intermedio de dirección como fuente de salto
      pc_out  => pc_out -- Entrega la dirección actual hacia el bus pc_out
    ); -- Finaliza el mapeo de puertos del PC

  ir_inst : instruction_register -- Instancia física del Registro de Instrucción
    port map ( -- Mapeo de puertos del IR
      clk  => clk, -- Conecta el reloj maestro
      rst  => rst_interno, -- Conecta el reset seguro interno
      en   => ir_en, -- Conecta la señal de control de habilitación
      din  => rom_data, -- Conecta el bus de datos crudos provenientes de la ROM
      dout => ir_out -- Expone la instrucción retenida hacia la unidad de control
    ); -- Finaliza el mapeo de puertos del IR

  rom_inst : rom -- Instancia física de la Memoria ROM
    port map ( -- Mapeo de puertos de la ROM
      addr => pc_out, -- Recibe la dirección directamente desde el PC
      dout => rom_data -- Entrega el código OP o dato pregrabado
    ); -- Finaliza el mapeo de puertos de la ROM

  process(clk, rst_interno) -- Proceso para el registro intermedio de captura de direcciones
  begin -- Inicia el proceso de captura de direcciones
    if rst_interno = '1' then -- Si hay un reset activo
      addr_reg <= (others => '0'); -- Limpia el registro poniéndolo todo en ceros
    elsif rising_edge(clk) then -- Sincronización con el reloj
      if addr_en = '1' then -- Si la Unidad de Control ordena capturar la dirección
        addr_reg <= rom_data; -- Memoriza el dato entregado por la ROM en ese instante
      end if; -- Fin de la validación de captura
    end if; -- Fin del if del reloj
  end process; -- Fin del proceso de captura de dirección

  ram_addr    <= addr_reg; -- Conecta de forma directa el registro de dirección a la entrada de dirección de la RAM
  ram_data_in <= reg_out1; -- El dato a guardar en la RAM proviene siempre de la salida principal del Banco de Registros

  ram_inst : ram -- Instancia física de la Memoria RAM
    port map ( -- Mapeo de puertos de la RAM
      clk  => clk, -- Conecta el reloj maestro
      rst  => rst_interno, -- Conecta el reset seguro
      addr => ram_addr, -- Conecta el bus de dirección de la RAM
      din  => ram_data_in, -- Conecta el bus de datos a escribir en RAM
      wen  => ram_wen, -- Conecta la señal de habilitación de escritura de RAM desde el control
      dout => ram_data_out -- Entrega el dato leído de la memoria
    ); -- Finaliza el mapeo de puertos de la RAM

  bank_addr_w  <= "00" when ir_out = OPC_LD else ir_out(1 downto 0); -- Decide destino: R0 forzado en LOAD, o bits de la instrucción
  bank_addr_r1 <= "00" when ir_out = OPC_ST else ir_out(3 downto 2); -- Decide origen: R0 forzado en STORE, o bits de la instrucción

  reg_din <= entrada_data when (reg_src = '1' and addr_reg = ADDR_ENTRADA) else -- MULTIPLEXOR: Si origen externo y apunta a FF, toma switches
             ram_data_out  when (reg_src = '1')                              else -- Si origen externo (memoria normal), toma el bus de RAM
             alu_result; -- Si origen es interno ('0'), retroalimenta el resultado directo de la ALU

  banco_inst : banco_registros -- Instancia física del Banco de Registros
    port map ( -- Mapeo de puertos del Banco
      clk     => clk, -- Reloj maestro
      rst     => rst_interno, -- Reset seguro
      addr_w  => bank_addr_w, -- Dirección de destino para escrituras
      addr_r1 => bank_addr_r1, -- Dirección del primer registro a leer
      addr_r2 => ir_out(5 downto 4), -- Dirección del segundo registro extraída de la instrucción
      din     => reg_din, -- Dato final a guardar seleccionado por el multiplexor previo
      wen     => reg_wen, -- Habilitador de escritura del control
      dout1   => reg_out1, -- Salida del primer operando hacia la ALU/RAM
      dout2   => reg_out2 -- Salida del segundo operando hacia la ALU
    ); -- Finaliza mapeo del Banco

  alu_inst : alu -- Instancia física de la ALU
    port map ( -- Mapeo de puertos de la ALU
      operand_a => reg_out1, -- Conecta el primer operando desde el banco de registros
      operand_b => reg_out2, -- Conecta el segundo operando desde el banco de registros
      opcode    => alu_op, -- Conecta la señal de código de operación desde la FSM de Control
      result    => alu_result -- Expone el resultado para ser retroalimentado al Banco
    ); -- Finaliza mapeo de la ALU

  control_inst : control_unit -- Instancia física de la Unidad de Control Principal
    port map ( -- Mapeo de puertos de la Unidad de Control
      clk     => clk, -- Conecta el reloj
      rst     => rst_interno, -- Conecta el reset seguro
      opcode  => ir_out, -- Recibe el código de instrucción del IR
      pc_inc  => pc_inc, -- Genera señal de incremento de PC
      pc_load => pc_load, -- Genera señal de carga de PC
      ir_en   => ir_en, -- Genera señal de habilitación de IR
      addr_en => addr_en, -- Genera señal de captura de dirección de memoria
      reg_wen => reg_wen, -- Genera señal para permitir escritura en registros
      reg_src => reg_src, -- Genera la señal selectora del multiplexor del banco
      ram_wen => ram_wen, -- Genera señal para permitir escritura en la RAM o Periféricos
      alu_op  => alu_op -- Genera el comando funcional directo para la ALU
    ); -- Finaliza mapeo de la FSM de Control

  process(clk, rst_interno) -- Proceso encargado de administrar el puerto mapeado de salida (x"FE")
  begin -- Inicia el proceso de salidas
    if rst_interno = '1' then -- Si hay un reset activo en el hardware
      salida_reg <= (others => '0'); -- Apaga completamente todas las salidas físicas
    elsif rising_edge(clk) then -- Sincronización en el flanco de reloj
      if ram_wen = '1' and addr_reg = ADDR_SALIDA then -- Si la orden es guardar en RAM y la dirección destino es x"FE"
        salida_reg <= reg_out1; -- Atrapa el dato en el registro físico de salida
      end if; -- Fin del filtro de dirección
    end if; -- Fin de la condición del reloj
  end process; -- Fin del proceso de salida

  led_out        <= salida_reg(1); -- Se mapea el bit 1 del registro físico de salida al pin exterior del LED
  ventilador_out <= salida_reg(0); -- Se mapea el bit 0 del registro físico de salida al pin exterior del ventilador

  process(clk, rst_interno) -- Proceso para gobernar el temporizador del modo automático independiente
  begin -- Inicio del proceso del temporizador automático
    if rst_interno = '1' then -- Si el sistema sufre un reinicio
      contador_auto <= (others => '0'); -- Borra el conteo acumulado de tiempo
      estado_auto   <= "00"; -- Regresa el generador de secuencias automáticas a cero
    elsif rising_edge(clk) then -- Sincronizado por el reloj de 50MHz de la FPGA
      if modo = '1' then -- Comprueba si el switch de Modo Automático está activado
        if contador_auto = PERIODO_AUTO - 1 then -- Si se alcanzó el límite temporal establecido (ej: 5 seg)
          contador_auto <= (others => '0'); -- Reinicia el contador para el próximo ciclo de tiempo
          estado_auto   <= std_logic_vector(unsigned(estado_auto) + 1); -- Incrementa el patrón que leerá el procesador
        else -- Si el tiempo límite aún no se ha cumplido
          contador_auto <= contador_auto + 1; -- Incrementa en 1 ciclo de reloj el contador interno
        end if; -- Fin de validación del periodo
      else -- Si el modo automático está apagado (Modo Manual)
        contador_auto <= (others => '0'); -- Mantiene inmovilizado y en cero el contador de tiempo
        estado_auto   <= "00"; -- Mantiene apagado y en cero el patrón de secuencias
      end if; -- Fin de la validación del switch de modo
    end if; -- Fin de la condición del reloj principal
  end process; -- Finaliza el proceso del generador automático

end architecture behave; -- Fin de la arquitectura principal del microprocesador Top Level
