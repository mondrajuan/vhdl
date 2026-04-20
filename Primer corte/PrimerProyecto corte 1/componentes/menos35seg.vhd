library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar señales digitales como std_logic
use IEEE.NUMERIC_STD.ALL; -- Permite usar operaciones matemáticas y conversiones

-- ENTIDAD (Define las entradas y salidas del componente)

entity menos35seg is 
    Port (
        clk              : in  std_logic; -- Reloj principal del componente
        reset_n          : in  std_logic; -- Botón de reset del componente
        start_n          : in  std_logic; -- Botón para iniciar el conteo
        stop_n           : in  std_logic; -- Botón para detener el conteo
        led_felicitacion : out std_logic; -- LED que indica éxito (paró antes de 35s)
        seguni_out       : out std_logic_vector(6 downto 0); -- Display de unidades del tiempo antes de 35s
        segdec_out       : out std_logic_vector(6 downto 0); -- Display de decenas del tiempo antes de 35s
        done_35s         : out std_logic  -- Señal que indica que se llegó a 35 segundos
    );
end menos35seg; -- Fin de la entidad

-- ARQUITECTURA (Aquí se diseña el funcionamiento interno)

architecture pro of menos35seg is

    -- COMPONENTE 1 (Divisor de frecuencia para generar reloj de 1 Hz)

    component contadorvhl is -- Declaración del divisor de frecuencia
        port(
            clk      : in  std_logic; -- Reloj de entrada
            freq_sel : in  std_logic_vector(1 downto 0); -- Selector de frecuencia
            clk_out  : out std_logic -- Reloj de salida dividido
        );
    end component; -- Fin del componente

    -- COMPONENTE 2 (Conversor BCD a display de 7 segmentos)

    component bcda7seg is -- Convierte números BCD a señales para el display
        port(
            A : in  std_logic_vector(3 downto 0); -- Entrada BCD
            D : out std_logic_vector(6 downto 0) -- Salida hacia display
        );
    end component; -- Fin del componente

    -- SEÑALES INTERNAS (Cables internos del sistema)

    signal clk_1hz         : std_logic; -- Reloj de 1Hz generado por el divisor
    signal total_seg       : integer range 0 to 35 := 0; -- Variable que guarda el conteo de segundos
    signal counting        : std_logic := '0'; -- Indica si el contador está activo
    signal start_n_prev    : std_logic := '1'; -- Guarda el valor anterior del botón start
    signal stop_n_prev     : std_logic := '1'; -- Guarda el valor anterior del botón stop
    signal start_flanco    : std_logic := '0'; -- Detecta cuando se presiona start
    signal stop_flanco     : std_logic := '0'; -- Detecta cuando se presiona stop
    signal clk_1hz_prev    : std_logic := '0'; -- Guarda el valor anterior del reloj de 1Hz

begin -- Inicio de la arquitectura

    -- INSTANCIA DEL DIVISOR DE FRECUENCIA

    u_clk: contadorvhl -- Se crea una instancia del divisor
        port map(
            clk => clk, -- Se conecta al reloj principal
            freq_sel => "00", -- Selección de frecuencia (configuración del divisor)
            clk_out => clk_1hz -- Salida del reloj dividido a 1Hz
        );

    -- INSTANCIA DEL DISPLAY DE UNIDADES

    u_seg_uni: bcda7seg -- Conversor para el display de unidades
        port map(
            A => std_logic_vector(to_unsigned(total_seg mod 10, 4)), -- Calcula las unidades del número
            D => seguni_out -- Salida hacia display unidades
        );

    -- INSTANCIA DEL DISPLAY DE DECENAS

    u_seg_dec: bcda7seg -- Conversor para el display de decenas
        port map(
            A => std_logic_vector(to_unsigned(total_seg / 10, 4)), -- Calcula las decenas del número
            D => segdec_out -- Salida hacia display decenas
        );

    -- DETECTOR DE FLANCOS DESCENDENTES DE LOS BOTONES

    process(clk) -- Proceso sincronizado con el reloj principal
    begin
        if rising_edge(clk) then -- Se ejecuta en cada flanco positivo del reloj
            start_n_prev <= start_n; -- Guarda el valor anterior del botón start
            stop_n_prev <= stop_n; -- Guarda el valor anterior del botón stop
            start_flanco <= '0'; -- Reinicia la señal de detección de start
            stop_flanco <= '0'; -- Reinicia la señal de detección de stop
            if start_n_prev = '1' and start_n = '0' then -- Detecta cambio de 1 a 0
                start_flanco <= '1'; -- Indica que el botón start fue presionado
            end if;         
            if stop_n_prev = '1' and stop_n = '0' then -- Detecta cambio de 1 a 0
                stop_flanco <= '1'; -- Indica que el botón stop fue presionado
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

    -- CONTADOR PRINCIPAL DE 0 A 35 SEGUNDOS
	 
    process(clk, reset_n) -- Proceso principal del contador
    begin
        if reset_n = '0' then -- Si se presiona reset
            total_seg <= 0; -- Reinicia el contador de segundos
            counting <= '0'; -- El contador queda detenido
            led_felicitacion <= '0'; -- Apaga el LED de felicitación
            done_35s <= '0'; -- Indica que aún no se ha llegado a 35
        elsif rising_edge(clk) then -- En cada flanco positivo del reloj
            
            -- INICIAR CONTEO

            if start_flanco = '1' then -- Si se presiona start
                counting <= '1'; -- Se activa el conteo
                total_seg <= 0; -- El contador inicia desde 0
                done_35s <= '0'; -- Reinicia señal de 35 segundos
                led_felicitacion <= '0'; -- Apaga LED de felicitación
            end if;

            -- DETENER CONTEO

            if stop_flanco = '1' and counting = '1' then -- Si se presiona stop mientras está contando
                counting <= '0'; -- Se detiene el contador

                if total_seg < 35 then -- Si el tiempo fue menor a 35 segundos
                    led_felicitacion <= '1'; -- Se enciende LED de éxito
                end if;
            end if;

            -- INCREMENTO DEL CONTADOR CADA SEGUNDO

            if clk_1hz_prev = '0' and clk_1hz = '1' and counting = '1' then -- Detecta flanco de subida del reloj de 1Hz
                if total_seg < 35 then -- Si el contador es menor a 35
                    total_seg <= total_seg + 1; -- Incrementa el contador en 1 segundo
                else
                    counting <= '0'; -- Se detiene el conteo
                    done_35s <= '1'; -- Indica que se llegó a 35 segundos
                end if;
            end if;
        end if;
    end process; -- Fin del proceso
end pro; -- Fin de la arquitectura