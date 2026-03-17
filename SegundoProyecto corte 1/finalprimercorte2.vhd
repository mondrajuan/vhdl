library IEEE; -- Se importa la librería estándar IEEE
use IEEE.STD_LOGIC_1164.ALL; -- Permite trabajar con señales digitales tipo std_logic
use IEEE.NUMERIC_STD.ALL; -- Permite usar operaciones numéricas con vectores
-- ENTIDAD (Define las entradas y salidas del sistema principal)
entity finalprimercorte2 is -- Módulo principal del proyecto
    port(
        clkO        : in  std_logic;                       -- Reloj principal
        start_btn   : in  std_logic;                       -- Botón para iniciar el conteo
        stop_btn    : in  std_logic;                       -- Botón para detener el conteo
        reset_btn   : in  std_logic;                       -- Botón para reiniciar el contador
        seg_uni     : out std_logic_vector(6 downto 0);    -- Salida para display de unidades
        seg_dec     : out std_logic_vector(6 downto 0);    -- Salida para display de decenas
        seg_min     : out std_logic_vector(7 downto 0)     -- Salida para display de minutos
    );
end entity;
-- ARQUITECTURA (Define el funcionamiento interno del sistema)
architecture pro of finalprimercorte2 is
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
    signal clka      : std_logic; -- Señal de reloj dividida
    signal enable    : std_logic := '0'; -- Señal que habilita o detiene el contador
    signal segU_bcd  : std_logic_vector(3 downto 0); -- BCD de unidades
    signal segD_bcd  : std_logic_vector(3 downto 0); -- BCD de decenas
    signal min_bcd   : std_logic_vector(3 downto 0); -- BCD de minutos
begin
    -- INSTANCIA DEL DIVISOR DE FRECUENCIA
    u_clk: contadorvhl -- Se crea una instancia del divisor de frecuencia
        port map(
            clk => clkO, -- Se conecta al reloj principal
            freq_sel => "00", -- ConfiguraciÃ³n del divisor de frecuencia
            clk_out => clka -- Salida del reloj dividido a 1Hz
        );
    -- PROCESO PARA CONTROLAR EL ENABLE DEL CONTADOR (Este proceso revisa los botones para iniciar, detener o reiniciar el conteo)
    process(clkO)
    begin
        if rising_edge(clkO) then -- Se ejecuta en cada flanco ascendente del reloj
            if reset_btn = '0' then -- Si se presiona reset
                enable <= '0'; -- Se desactiva el contador
            elsif start_btn = '0' then -- Si se presiona start
                enable <= '1'; -- Se activa el contador
            elsif stop_btn = '0' then -- Si se presiona stop
                enable <= '0'; -- Se detiene el contador
            end if;
        end if;
    end process;
    -- INSTANCIA DEL CONTADOR PRINCIPAL (Cuenta el tiempo y genera los valores BCD para los displays)
    contador: contador7seg
        port map(
            clkE   => clka and enable, -- El contador solo funciona si enable está activo
            reset  => reset_btn,	-- Reset controlado por el botón	  
            seguni => segU_bcd, -- Salida BCD de unidades
            segdec => segD_bcd, -- Salida BCD de decenas
            min    => min_bcd -- Salida BCD de minutos
        );
    -- DECODIFICADORES BCD A 7 SEGMENTOS (Convierten los valores BCD en señales para los displays)
    dec_uni: bcda7seg port map(A => segU_bcd, D => seg_uni); -- Display unidades
    dec_dec: bcda7seg port map(A => segD_bcd, D => seg_dec); -- Display decenas
    dec_min: bcda7seg port map(A => min_bcd, D => seg_min(6 downto 0)); -- Display minutos
    seg_min(7) <= '0'; -- Se mantiene apagado el punto decimal
end architecture pro; -- Fin de la arquitectura