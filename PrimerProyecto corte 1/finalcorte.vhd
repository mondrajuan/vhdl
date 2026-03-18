library IEEE; -- Se importa la librería estándar de IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar tipos de datos digitales como std_logic
-- Entidad (Aquí se definen TODAS las entradas y salidas del sistema)
entity finalcorte is -- Nombre del módulo principal del proyecto
    Port ( -- Inicio de la definición de puertos
        clk              : in  std_logic;  -- Reloj principal del sistema que sincroniza todo
        reset_n          : in  std_logic;  -- Botón de reset que reinicia todo el sistema
        start_n          : in  std_logic;  -- Botón que inicia el conteo
        stop_n           : in  std_logic;  -- Botón que detiene el conteo
        led_alarma       : out std_logic;  -- LED que se enciende si se superan los 35 segundos
        led_felicitacion : out std_logic;  -- LED que se enciende si se detiene antes de 35 segundos
        seguni_exceso    : out std_logic_vector(6 downto 0); -- Display unidades para tiempo después de 35s
        segdec_exceso    : out std_logic_vector(6 downto 0); -- Display decenas para tiempo después de 35s
        seguni_menos35   : out std_logic_vector(6 downto 0); -- Display unidades para tiempo antes de 35s
        segdec_menos35   : out std_logic_vector(6 downto 0)  -- Display decenas para tiempo antes de 35s
    );
end finalcorte; -- Fin de la entidad
-- ARCHITECTURE (Se diseña el funcionamiento interno del sistema)
architecture pro of finalcorte is -- Se define la arquitectura del sistema
    -- COMPONENTE 1 (Contador que se activa cuando se superan los 35 segundos)
    component finalcarot12 is -- Declaración del componente contador de exceso
        Port (
            clk        : in  std_logic; -- Reloj del componente
            reset_n    : in  std_logic; -- Reset interno del componente
            start_35s  : in  std_logic; -- Señal que indica que ya se llegó a 35s
            stop_n     : in  std_logic; -- Botón para detener el contador
            led_alarma : out std_logic; -- LED que indica exceso de tiempo
            seguni_out : out std_logic_vector(6 downto 0); -- Display unidades del exceso
            segdec_out : out std_logic_vector(6 downto 0)  -- Display decenas del exceso
        );
    end component; -- Fin del componente
    -- COMPONENTE 2 (Contador que funciona desde 0 hasta 35 segundos)
    component menos35seg is -- Declaración del contador principal
        Port (
            clk              : in  std_logic; -- Reloj del componente
            reset_n          : in  std_logic; -- Reset interno
            start_n          : in  std_logic; -- Botón que inicia el conteo
            stop_n           : in  std_logic; -- Botón que detiene el conteo
            led_felicitacion : out std_logic; -- LED que indica éxito
            seguni_out       : out std_logic_vector(6 downto 0); -- Display unidades
            segdec_out       : out std_logic_vector(6 downto 0); -- Display decenas
            done_35s         : out std_logic  -- Señal que indica que se llegó a 35 segundos
        );
    end component; -- Fin del componente
    -- SEÑALES INTERNAS (Son cables internos que conectan los módulos)
    signal led_alarma_int       : std_logic; -- Señal interna para LED de alarma
    signal seguni_exceso_int    : std_logic_vector(6 downto 0); -- Señal interna unidades exceso
    signal segdec_exceso_int    : std_logic_vector(6 downto 0); -- Señal interna decenas exceso
    signal led_felicitacion_int : std_logic; -- Señal interna LED felicitación
    signal seguni_menos35_int   : std_logic_vector(6 downto 0); -- Señal interna unidades contador principal
    signal segdec_menos35_int   : std_logic_vector(6 downto 0); -- Señal interna decenas contador principal
    signal done_35s_int         : std_logic; -- Señal que indica que se llegó a 35 segundos
    signal start_n_prev         : std_logic := '1'; -- Guarda el valor anterior del botón start
    signal stop_n_prev          : std_logic := '1'; -- Guarda el valor anterior del botón stop
    signal start_flanco         : std_logic := '0'; -- Señal que detecta flanco de bajada en start
    signal stop_flanco          : std_logic := '0'; -- Señal que detecta flanco de bajada en stop
    type state_type is (IDLE, COUNTING, DONE_OK, DONE_EXCESO); -- Definición de los estados del sistema
    signal state : state_type := IDLE; -- Estado inicial del sistema
begin -- Inicio de la arquitectura
    -- Instancia del contador de exceso
    u_exceso: finalcarot12 -- Se crea una instancia del componente
        port map( -- Conexión de sus puertos
            clk        => clk, -- Se conecta al reloj principal
            reset_n    => reset_n, -- Se conecta al reset
            start_35s  => done_35s_int, -- Se activa cuando se llega a 35 segundos
            stop_n     => stop_n, -- Se conecta al botón stop
            led_alarma => led_alarma_int, -- Salida hacia señal interna
            seguni_out => seguni_exceso_int, -- Display unidades exceso
            segdec_out => segdec_exceso_int -- Display decenas exceso
        );
    -- Instancia del contador principal (0 a 35 segundos)
    u_menos35: menos35seg -- Instancia del contador principal
        port map(
            clk              => clk, -- Conectado al reloj
            reset_n          => reset_n, -- Conectado al reset
            start_n          => start_n, -- Conectado al botón start
            stop_n           => stop_n, -- Conectado al botón stop
            led_felicitacion => led_felicitacion_int, -- LED de felicitación
            seguni_out       => seguni_menos35_int, -- Display unidades
            segdec_out       => segdec_menos35_int, -- Display decenas
            done_35s         => done_35s_int -- Señal que indica que llegó a 35 segundos
        );
    -- Proceso que detecta cuando se presiona un botón (detección de flancos)
    process(clk) -- Proceso sincronizado con el reloj
    begin
        if rising_edge(clk) then -- Se ejecuta en cada flanco positivo del reloj
            start_n_prev <= start_n; -- Guarda el valor anterior del botón start
            stop_n_prev <= stop_n; -- Guarda el valor anterior del botón stop
            start_flanco <= '0'; -- Reinicia señal de detección de start
            stop_flanco <= '0'; -- Reinicia señal de detección de stop
            if start_n_prev = '1' and start_n = '0' then -- Detecta cambio de 1 a 0
                start_flanco <= '1'; -- Indica que el botón start fue presionado
            end if;
            if stop_n_prev = '1' and stop_n = '0' then -- Detecta cambio de 1 a 0
                stop_flanco <= '1'; -- Indica que el botón stop fue presionado
            end if;
        end if;
    end process;
    -- Máquina de estados principal del sistema
    process(clk, reset_n) -- Proceso dependiente del reloj y del reset
    begin
        if reset_n = '0' then -- Si se presiona reset
            state <= IDLE; -- El sistema vuelve al estado inicial
            led_felicitacion <= '0'; -- Apaga LED de felicitación
            led_alarma <= '0'; -- Apaga LED de alarma
        elsif rising_edge(clk) then -- En cada flanco positivo del reloj
            case state is -- Se evalúa el estado actual
                when IDLE => -- Estado inicial (esperando start)
                    if start_flanco = '1' then -- Si se presiona start
                        state <= COUNTING; -- Se pasa al estado de conteo
                    end if;
                when COUNTING => -- Estado donde el sistema está contando
                    if stop_flanco = '1' then -- Si se presiona stop antes de 35
                        state <= DONE_OK; -- Estado de éxito
                        led_felicitacion <= '1'; -- Se enciende LED de felicitación
                    elsif done_35s_int = '1' then -- Si el contador llega a 35
                        state <= DONE_EXCESO; -- Estado de exceso
                        led_alarma <= '1'; -- Se enciende LED de alarma
                    end if;
                when DONE_OK | DONE_EXCESO => -- Estados finales
                    null; -- El sistema queda detenido hasta reset
            end case;
        end if;
    end process;
    -- Proceso que decide qué displays se deben mostrar
    process(state, seguni_menos35_int, segdec_menos35_int,
            seguni_exceso_int, segdec_exceso_int)
    begin
        if state = COUNTING or state = DONE_OK then -- Mientras se cuenta o terminó bien
            seguni_menos35 <= seguni_menos35_int; -- Muestra unidades del contador principal
            segdec_menos35 <= segdec_menos35_int; -- Muestra decenas del contador principal
            seguni_exceso  <= (others => '0'); -- Apaga display exceso unidades
            segdec_exceso  <= (others => '0'); -- Apaga display exceso decenas
        elsif state = DONE_EXCESO then -- Si se pasó de 35 segundos
            seguni_exceso  <= seguni_exceso_int; -- Muestra unidades del exceso
            segdec_exceso  <= segdec_exceso_int; -- Muestra decenas del exceso
            seguni_menos35 <= seguni_menos35_int; -- Mantiene congelado el valor del contador principal
            segdec_menos35 <= segdec_menos35_int; -- Mantiene congelado el valor del contador principal
        else -- Estado IDLE
            seguni_menos35 <= (others => '0'); -- Apaga display
            segdec_menos35 <= (others => '0'); -- Apaga display
            seguni_exceso  <= (others => '0'); -- Apaga display
            segdec_exceso  <= (others => '0'); -- Apaga display
        end if;
    end process;
end pro; -- Fin de la arquitectura