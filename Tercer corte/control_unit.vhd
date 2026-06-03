library ieee; -- Se importa la librería estándar IEEE
use ieee.std_logic_1164.all; -- Habilita el manejo de vectores y estados lógicos digitales
use ieee.numeric_std.all; -- Necesario por compatibilidad y posibles extensiones numéricas

-- ENTIDAD DE LA UNIDAD DE CONTROL (El cerebro del procesador, genera las señales de control de todo el sistema)
entity control_unit is
  port (
    clk     : in  std_logic;                    -- Reloj principal para avanzar en los estados de la FSM
    rst     : in  std_logic;                    -- Reset síncrono/asíncrono para retornar al estado inicial
    opcode  : in  std_logic_vector(7 downto 0); -- Código de operación de la instrucción actual (desde el IR)
    pc_inc  : out std_logic;                    -- Señal de control: Incrementa el Program Counter en 1
    pc_load : out std_logic;                    -- Señal de control: Carga un valor de salto en el Program Counter
    ir_en   : out std_logic;                    -- Señal de control: Habilita la escritura en el Registro de Instrucción
    addr_en : out std_logic;                    -- Señal de control: Captura y habilita la dirección de memoria RAM/ROM
    reg_wen : out std_logic;                    -- Señal de control: Habilita la escritura en el Banco de Registros
    reg_src : out std_logic;                    -- Señal de control: Elige origen de datos (1 = Memoria/Entrada, 0 = ALU)
    ram_wen : out std_logic;                    -- Señal de control: Habilita la escritura en la memoria RAM
    alu_op  : out std_logic_vector(2 downto 0)  -- Señal de control: Envía el código de función directo a la ALU
  );
end entity control_unit;

-- ARQUITECTURA (Define la máquina de estados secuencial y las salidas de control según la instrucción)
architecture rtl of control_unit is
  -- DECLARACIÓN DE LOS ESTADOS DE LA FSM (Ciclo clásico de ejecución de instrucciones)
  type state_type is (FETCH, DECODE, FETCH_ADDR, EXECUTE);
  signal state, next_state : state_type; -- Señales para almacenar el estado presente y el calculado siguiente
  
  -- DEFINICIÓN DEL SET DE INSTRUCCIONES (Códigos OP de cada instrucción en formato Hexadecimal)
  constant OPC_LD  : std_logic_vector(7 downto 0) := x"01"; -- Cargar dato desde Memoria/Entrada a R0
  constant OPC_ST  : std_logic_vector(7 downto 0) := x"02"; -- Almacenar dato de R0 en una dirección de RAM/Salida
  constant OPC_ADD : std_logic_vector(7 downto 0) := x"03"; -- Sumar registros en la ALU
  constant OPC_SUB : std_logic_vector(7 downto 0) := x"04"; -- Restar registros en la ALU
  -- MODIFICADO: Se asigna el código 00 para permitir paso por la ALU usando R0
  constant OPC_AND : std_logic_vector(7 downto 0) := x"00"; -- Operación AND lógica bit a bit
  constant OPC_OR  : std_logic_vector(7 downto 0) := x"06"; -- Operación OR lógica bit a bit
  constant OPC_NOT : std_logic_vector(7 downto 0) := x"07"; -- Operación NOT lógica (Inversor)
  constant OPC_JMP : std_logic_vector(7 downto 0) := x"08"; -- Salto incondicional de la línea de programa
begin
  -- PROCESO SECUENCIAL: Controla el cambio de estado físico sincronizado por el reloj
  process(clk, rst)
  begin
    if rst = '1' then -- Si el reset está activo
      state <= FETCH; -- Retorna al estado inicial de búsqueda de instrucción
    elsif rising_edge(clk) then -- Flanco de subida de reloj
      state <= next_state; -- Realiza la transición al estado calculado
    end if;
  end process;

  -- PROCESO COMBINACIONAL: Define el valor de las salidas y el próximo estado según el opcode
  process(state, opcode)
  begin
    -- VALORES POR DEFECTO: Evita la creación no deseada de Latches (Memorias parásitas)
    pc_inc     <= '0';
    pc_load    <= '0';
    ir_en      <= '0';
    addr_en    <= '0';
    reg_wen    <= '0';
    reg_src    <= '0';
    ram_wen    <= '0';
    alu_op     <= "000";
    next_state <= FETCH; -- Por defecto, ante fallos, regresa a FETCH

    -- Máquina de estados principal
    case state is
      when FETCH => -- ESTADO: Búsqueda de la instrucción en la ROM
        ir_en      <= '1'; -- Abre el Registro de Instrucción para memorizar el código actual
        pc_inc     <= '1'; -- Avanza el PC para apuntar al operando o a la siguiente instrucción
        next_state <= DECODE; -- Pasa al estado de decodificación
        
      when DECODE => -- ESTADO: Análisis de la instrucción cargada
        -- Si la instrucción requiere acceder a una dirección intermedia (LD, ST, JMP)...
        if opcode = OPC_LD or opcode = OPC_ST or opcode = OPC_JMP then
          next_state <= FETCH_ADDR; -- Va primero a capturar esa dirección
        else
          next_state <= EXECUTE; -- Si es aritmética o lógica directa, pasa directo a ejecutar
        end if;
        
      when FETCH_ADDR => -- ESTADO: Captura de la dirección asociada a la instrucción
        addr_en    <= '1'; -- Habilita el registro intermedio de direccionamiento para leer la ROM
        pc_inc     <= '1'; -- Avanza el PC de largo para saltarse el byte de la dirección capturada
        next_state <= EXECUTE; -- Ahora que tiene el dato de dirección, pasa a ejecución
        
      when EXECUTE => -- ESTADO: Ejecución de las operaciones en el procesador
        case opcode is
          when OPC_LD => -- Instrucción LOAD
            reg_wen <= '1'; -- Permite escribir en el banco de registros
            reg_src <= '1'; -- Define que el origen viene desde la memoria externa/puerto
            next_state <= FETCH; -- Ciclo finalizado, busca la siguiente instrucción
          when OPC_ST => -- Instrucción STORE
            ram_wen <= '1'; -- Activa la señal de escritura en la RAM o registro de salida
            next_state <= FETCH; -- Regresa al ciclo inicial
          when OPC_ADD => -- Instrucción ADD
            alu_op  <= "000"; -- Configura la ALU en modo Suma
            reg_wen <= '1'; -- Habilita guardar el resultado en el banco
            reg_src <= '0'; -- Indica que el origen del dato proviene directamente de la ALU
            next_state <= FETCH; -- Termina ejecución
          when OPC_SUB => -- Instrucción SUB
            alu_op  <= "001"; -- Configura la ALU en modo Resta
            reg_wen <= '1'; -- Habilita guardar el resultado en el banco
            reg_src <= '0'; -- El dato viene de la ALU
            next_state <= FETCH; -- Termina ejecución
          when OPC_AND => -- Instrucción AND
            alu_op  <= "010"; -- Configura la ALU en modo AND lógico
            reg_wen <= '1'; -- Habilita guardar en el banco
            reg_src <= '0'; -- El dato viene de la ALU
            next_state <= FETCH; -- Termina ejecución
          when OPC_OR => -- Instrucción OR
            alu_op  <= "011"; -- Configura la ALU en modo OR lógico
            reg_wen <= '1'; -- Habilita guardar en el banco
            reg_src <= '0'; -- El dato viene de la ALU
            next_state <= FETCH; -- Termina ejecución
          when OPC_NOT => -- Instrucción NOT
            alu_op  <= "100"; -- Configura la ALU en modo Inversión
            reg_wen <= '1'; -- Habilita guardar en el banco
            reg_src <= '0'; -- El dato viene de la ALU
            next_state <= FETCH; -- Termina ejecución
          when OPC_JMP => -- Instrucción JUMP (Salto)
            pc_load <= '1'; -- Habilita la carga forzada de una dirección en el PC
            next_state <= FETCH; -- Salta y empieza el FETCH en la nueva dirección cargada
          when others => -- Instrucciones desconocidas o vacías
            next_state <= FETCH; -- Ignora y vuelve a iniciar
        end case;
    end case;
  end process;
end architecture rtl;
