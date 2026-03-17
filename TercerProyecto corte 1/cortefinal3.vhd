library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite usar señales digitales
use IEEE.NUMERIC_STD.ALL; -- Permite operaciones numéricas
-- ENTIDAD (Define las entradas y salidas del sistema)
entity cortefinal3 is -- Módulo principal del sistema
    port(
        clkO    : in  std_logic; -- Reloj principal
        bton    : in  std_logic; -- Botón único de control
        seg_uni : out std_logic_vector(6 downto 0); -- Display unidades
        seg_dec : out std_logic_vector(6 downto 0); -- Display decenas
        seg_min : out std_logic_vector(7 downto 0)  -- Display minutos
    );
end cortefinal3; -- Fin de la entidad
-- ARQUITECTURA (Aquí se define el funcionamiento interno del contador)
architecture pro of cortefinal3 is
    -- DECLARACIÓN DE COMPONENTES
    component contadorvhl is -- Divisor de frecuencia
        port(
            clk      : in  std_logic; -- Reloj de entrada
            freq_sel : in  std_logic_vector(1 downto 0); -- Selector de frecuencia
            clk_out  : out std_logic -- Reloj dividido
        );
    end component;
    component bcda7seg is -- Decodificador BCD a 7 segmentos
        port(
            A : in  std_logic_vector(3 downto 0); -- Entrada BCD
            D : out std_logic_vector(6 downto 0) -- Salida para display
        );
    end component;
    component contador7seg is -- Contador principal
        port(
            clkE   : in std_logic; -- Reloj habilitado
            reset  : in std_logic; -- Reset del sistema
            seguni : out std_logic_vector(3 downto 0); -- Unidades en BCD
            segdec : out std_logic_vector(3 downto 0); -- Decenas en BCD
            min    : out std_logic_vector(3 downto 0) -- Minutos en BCD
        );
    end component;
-- SEÑALES INTERNAS (Son cables internos que conectan los módulos)
    signal clka         : std_logic := '0'; -- Reloj dividido
    signal clk_btn      : std_logic := '0'; -- Reloj lento para lectura del botón (anti-rebote)
    signal segU_bcd     : std_logic_vector(3 downto 0); -- BCD unidades
    signal segD_bcd     : std_logic_vector(3 downto 0); -- BCD decenas
    signal min_bcd      : std_logic_vector(3 downto 0); -- BCD minutos
    signal enable       : std_logic := '0'; -- Habilita el contador
    signal s_reset      : std_logic := '1'; -- Señal de reset interno
    signal clk_contador : std_logic; -- Reloj final hacia el contador
    signal btn_prev     : std_logic := '1'; -- Estado anterior del botón
    signal press_cnt    : integer := 0; -- Contador de duración de la pulsación
    signal btn_filter   : integer := 0; -- Contador para generar reloj lento (anti-rebote)
begin
    -- INSTANCIA DEL DIVISOR DE FRECUENCIA
    u_clk: contadorvhl -- Se crea una instancia del divisor de frecuencia
        port map(
            clk => clkO, -- Se conecta al reloj principal
            freq_sel => "00", -- ConfiguraciÃ³n del divisor de frecuencia
            clk_out => clka -- Salida del reloj dividido a 1Hz
        );
    -- Se reduce la frecuencia para leer correctamente el botón
    process(clkO)
    begin
        if rising_edge(clkO) then
            if btn_filter = 499999 then -- Cuando alcanza cierto valor
                clk_btn <= not clk_btn; -- Cambia el estado del reloj lento
                btn_filter <= 0; -- Reinicia el contador
            else
                btn_filter <= btn_filter + 1; -- Sigue contando
            end if;
        end if;
    end process;
    -- PROCESO DE CONTROL DEL BOTÓN
    process(clk_btn)
    begin
        if rising_edge(clk_btn) then
            s_reset <= '1'; -- Por defecto no hay reset
            -- DETECCIÓN DE FLANCO (cuando se presiona el botón)
            if btn_prev = '1' and bton = '0' then
                press_cnt <= 0; -- Reinicia el contador de pulsación
            end if;
            -- SI EL BOTÓN ESTÁ PRESIONADO
            if bton = '0' then
                press_cnt <= press_cnt + 1; -- Cuenta cuánto dura presionado
                if press_cnt >= 100 then -- Pulsación larga
                    s_reset <= '0'; -- Activa reset
                    enable <= '0';  -- Detiene el contador
                end if;
            else -- SI EL BOTÓN SE SUELTA
                if btn_prev = '0' then -- Detecta liberación del botón
                    if press_cnt < 100 then -- Pulsación corta
                        enable <= not enable; -- Alterna entre iniciar/detener
                    end if;
                end if;
                press_cnt <= 0; -- Reinicia contador
            end if;
            btn_prev <= bton; -- Guarda estado anterior del botón
        end if;
    end process;
    -- Solo permite el paso del reloj si enable está activo
    clk_contador <= clka when enable = '1' else '0';

 -- INSTANCIA DEL CONTADOR PRINCIPAL (Cuenta el tiempo y genera los valores BCD para los displays)
    u_contador: contador7seg
        port map(
            clkE   => clk_contador, -- Reloj habilitado
            reset  => s_reset,      -- Reset controlado por el botón
            seguni => segU_bcd,     -- Salida BCD de unidades
            segdec => segD_bcd,		-- Salida BCD de decenas
            min    => min_bcd			-- Salida BCD de minutos
        );
 -- DECODIFICADORES BCD A 7 SEGMENTOS (Convierten los valores BCD en señales para los displays)
    dec_uni: bcda7seg port map(A => segU_bcd, D => seg_uni); -- Unidades
    dec_dec: bcda7seg port map(A => segD_bcd, D => seg_dec); -- Decenas
    dec_min: bcda7seg port map(A => min_bcd, D => seg_min(6 downto 0)); -- Minutos
    seg_min(7) <= '0'; -- Mantiene apagado el punto decimal
end pro; -- Fin de la arquitectura