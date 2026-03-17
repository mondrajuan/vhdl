library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar señales digitales como std_logic
use IEEE.NUMERIC_STD.ALL; -- Permite hacer operaciones matemáticas y conversiones

-- ENTIDAD (Define las entradas y salidas del componente)

entity finalcarot12 is -- Nombre del módulo que cuenta el tiempo de exceso
    Port (
        clk        : in  std_logic; -- Reloj principal del componente
        reset_n    : in  std_logic; -- Botón de reset del componente
        start_35s  : in  std_logic; -- Señal que indica que ya se llegó a 35 segundos
        stop_n     : in  std_logic; -- Botón para detener el conteo de exceso
        led_alarma : out std_logic; -- LED que indica que hay exceso de tiempo
        seguni_out : out std_logic_vector(6 downto 0); -- Display de unidades del tiempo de exceso
        segdec_out : out std_logic_vector(6 downto 0) -- Display de decenas del tiempo de exceso
    );
end finalcarot12; -- Fin de la entidad

-- ARQUITECTURA (Aquí se diseña el funcionamiento interno)

architecture pro of finalcarot12 is

    -- COMPONENTE 1 (Divisor de frecuencia para obtener reloj de 1 Hz)

    component contadorvhl is -- Declaración del divisor de frecuencia
        port(
            clk      : in  std_logic; -- Reloj de entrada
            freq_sel : in  std_logic_vector(1 downto 0); -- Selector de frecuencia
            clk_out  : out std_logic -- Reloj de salida dividido
        );
    end component; -- Fin del componente

    -- COMPONENTE 2 (Conversor BCD a display de 7 segmentos)

    component bcda7seg is -- Convierte un número BCD en señales para el display
        port(
            A : in  std_logic_vector(3 downto 0); -- Entrada BCD
            D : out std_logic_vector(6 downto 0) -- Salida hacia el display
        );
    end component; -- Fin del componente

    -- SEÑALES INTERNAS (Cables internos del sistema)

    signal clk_1hz      : std_logic; -- Reloj de 1Hz generado por el divisor
    signal exceso_seg   : integer range 0 to 99 := 0; -- Variable que guarda los segundos de exceso
    signal alarma       : std_logic := '0'; -- Señal interna que controla el LED de alarma
    signal counting     : std_logic := '0'; -- Indica si el contador de exceso está activo
    signal stop_n_prev  : std_logic := '1'; -- Guarda el valor anterior del botón stop
    signal stop_flanco  : std_logic := '0'; -- Detecta cuando se presiona stop
    signal clk_1hz_prev : std_logic := '0'; -- Guarda el valor anterior del reloj de 1Hz
    signal start_35s_prev : std_logic := '0'; -- Guarda el valor anterior de la señal start_35s
    signal start_flanco : std_logic := '0'; -- Detecta cuando se activa start_35s

begin -- Inicio de la arquitectura

    -- INSTANCIA DEL DIVISOR DE FRECUENCIA

    u_clk: contadorvhl -- Se crea una instancia del divisor de frecuencia
        port map(
            clk => clk, -- Se conecta al reloj principal
            freq_sel => "00", -- Configuración del divisor de frecuencia
            clk_out => clk_1hz -- Salida del reloj dividido a 1Hz
        );

    -- INSTANCIA DEL DISPLAY DE UNIDADES

    u_seg_uni: bcda7seg -- Conversor para el display de unidades
        port map(
            A => std_logic_vector(to_unsigned(exceso_seg mod 10, 4)), -- Calcula las unidades del número
            D => seguni_out -- Salida hacia el display de unidades
        );

    -- INSTANCIA DEL DISPLAY DE DECENAS

    u_seg_dec: bcda7seg -- Conversor para el display de decenas
        port map(
            A => std_logic_vector(to_unsigned(exceso_seg / 10, 4)), -- Calcula las decenas del número
            D => segdec_out -- Salida hacia el display de decenas
        );

    -- DETECTOR DE FLANCOS (Para detectar cuando cambian las señales)

    process(clk) -- Proceso sincronizado con el reloj principal
    begin
        if rising_edge(clk) then -- Se ejecuta en cada flanco positivo del reloj
            stop_n_prev <= stop_n; -- Guarda el valor anterior del botón stop
            start_35s_prev <= start_35s; -- Guarda el valor anterior de la señal start_35s
            stop_flanco <= '0'; -- Reinicia la señal de detección de stop
            start_flanco <= '0'; -- Reinicia la señal de detección de start 
            if stop_n_prev = '1' and stop_n = '0' then -- Detecta cambio de 1 a 0 en stop
                stop_flanco <= '1'; -- Indica que el botón stop fue presionado
            end if;
            if start_35s_prev = '0' and start_35s = '1' then -- Detecta cambio de 0 a 1 en start_35s
                start_flanco <= '1'; -- Indica que se activó el conteo de exceso
            end if;
        end if;
    end process; -- Fin del proceso

    -- DETECTOR DE FLANCO ASCENDENTE DEL RELOJ DE 1Hz

    process(clk, reset_n) -- Proceso sincronizado con clk y reset
    begin
        if reset_n = '0' then -- Si se presiona reset
            clk_1hz_prev <= '0'; -- Se reinicia el valor anterior del reloj
        elsif rising_edge(clk) then -- En cada flanco del reloj
            clk_1hz_prev <= clk_1hz; -- Guarda el valor anterior del reloj de 1Hz
        end if;
    end process; -- Fin del proceso

    -- CONTADOR DE EXCESO (Cuenta el tiempo después de 35 segundos)

    process(clk, reset_n) -- Proceso principal del contador de exceso
    begin
        if reset_n = '0' then -- Si se presiona reset

            exceso_seg <= 0; -- Reinicia el contador de exceso
            alarma <= '0'; -- Apaga la alarma
            counting <= '0'; -- Detiene el conteo
        elsif rising_edge(clk) then -- En cada flanco positivo del reloj
            
            -- INICIAR CONTEO CUANDO SE SUPERA 35 SEGUNDOS

            if start_flanco = '1' then -- Si se activa la señal start_35s
                counting <= '1'; -- Se inicia el conteo de exceso
                exceso_seg <= 0; -- El contador inicia desde 0
                alarma <= '1'; -- Se enciende la alarma
            end if;

            -- DETENER CONTEO SI SE PRESIONA STOP

            if stop_flanco = '1' and counting = '1' then -- Si se presiona stop mientras cuenta
                counting <= '0'; -- Se detiene el contador
                alarma <= '0'; -- Se apaga la alarma
            end if;

            -- INCREMENTAR EL CONTADOR CADA SEGUNDO

            if clk_1hz_prev = '0' and clk_1hz = '1' and counting = '1' then -- Detecta flanco de subida del reloj de 1Hz
                exceso_seg <= exceso_seg + 1; -- Incrementa el contador de exceso
            end if;
        end if;
    end process; -- Fin del proceso
    led_alarma <= alarma; -- Se conecta la señal interna alarma con la salida LED
end pro; -- Fin de la arquitectura