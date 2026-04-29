library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mem_pkg.all;

entity ROMRAM is
  port(
    CLOCK_50 : in  std_logic;
    rst      : in  std_logic;
    freq_sel : in  std_logic_vector(1 downto 0);
    HEX0     : out std_logic_vector(6 downto 0);
    HEX1     : out std_logic_vector(6 downto 0);
    HEX2     : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of ROMRAM is
  -- Estados de la máquina
  type state_type is (ESTADO_LECTURA_ROM, ESTADO_GUARDAR_RAM, ESTADO_LEER_RAM, ESTADO_MOSTRAR);
  signal estado_actual  : state_type;
  signal estado_siguiente : state_type;
  
  signal clk_sel      : std_logic;
  signal contador_estado : integer := 0;
  signal indice_dato   : integer := 0;
  
  signal rom_addr : std_logic_vector(3 downto 0);
  signal rom_data : std_logic_vector(7 downto 0);
  
  signal ram_addr_read  : std_logic_vector(3 downto 0);
  signal ram_addr_write : std_logic_vector(3 downto 0);
  signal ram_data_read  : std_logic_vector(7 downto 0);
  signal ram_data_write : std_logic_vector(7 downto 0);
  signal ram_we         : std_logic;
  
  signal dato_mostrar_0 : std_logic_vector(7 downto 0);
  signal dato_mostrar_1 : std_logic_vector(7 downto 0);
  signal dato_mostrar_2 : std_logic_vector(7 downto 0);

begin
  
  -- Divisor de frecuencia seleccionable
  u_div : contadorvhl
    port map(
      clk       => CLOCK_50,
      freq_sel  => freq_sel,
      clk_out   => clk_sel
    );

  -- ROM con 4 datos iniciales (0xAA, 0x55, 0xF0, 0x0F)
  u_rom : rom_sync
    generic map(DATA_WIDTH => 8, ADDR_WIDTH => 4)
    port map(
      clk      => CLOCK_50,
      addr     => rom_addr,
      data_out => rom_data
    );

  -- RAM para almacenar los datos
  u_ram : ram_sincrona
    generic map(DATA_WIDTH => 8, ADDR_WIDTH => 4, RDW_MODE => "READ_FIRST")
    port map(
      clk      => CLOCK_50,
      rd_en    => '1',
      wr_en    => ram_we,
      addr     => ram_addr_write when ram_we = '1' else ram_addr_read,
      data_in  => ram_data_write,
      data_out => ram_data_read
    );

  -- Decodificadores 7 segmentos
  u0: dec7seg port map(char => dato_mostrar_0, seg => HEX0);
  u1: dec7seg port map(char => dato_mostrar_1, seg => HEX1);
  u2: dec7seg port map(char => dato_mostrar_2, seg => HEX2);

  -- Máquina de estados
  process(clk_sel, rst)
  begin
    if rst = '1' then
      estado_actual <= ESTADO_LECTURA_ROM;
      indice_dato <= 0;
      contador_estado <= 0;
    elsif rising_edge(clk_sel) then
      estado_actual <= estado_siguiente;
      
      case estado_actual is
        when ESTADO_LECTURA_ROM =>
          -- Se cuentan 4 ciclos para leer los 4 datos
          if contador_estado < 3 then
            contador_estado <= contador_estado + 1;
          else
            contador_estado <= 0;
            indice_dato <= 0;
            estado_siguiente <= ESTADO_GUARDAR_RAM;
          end if;
          
        when ESTADO_GUARDAR_RAM =>
          -- Se cuentan 4 ciclos para guardar en RAM
          if contador_estado < 3 then
            contador_estado <= contador_estado + 1;
          else
            contador_estado <= 0;
            indice_dato <= 0;
            estado_siguiente <= ESTADO_LEER_RAM;
          end if;
          
        when ESTADO_LEER_RAM =>
          -- Se cuentan 4 ciclos para leer de RAM
          if contador_estado < 3 then
            contador_estado <= contador_estado + 1;
          else
            contador_estado <= 0;
            estado_siguiente <= ESTADO_MOSTRAR;
          end if;
          
        when ESTADO_MOSTRAR =>
          -- Se mantiene mostrando los datos
          contador_estado <= 0;
          
      end case;
    end if;
  end process;

  -- Lógica combinacional de direcciones y datos
  process(estado_actual, indice_dato, rom_data, ram_data_read)
  begin
    -- Valores por defecto
    rom_addr <= (others => '0');
    ram_addr_read <= (others => '0');
    ram_addr_write <= (others => '0');
    ram_data_write <= (others => '0');
    ram_we <= '0';
    dato_mostrar_0 <= x"00";
    dato_mostrar_1 <= x"00";
    dato_mostrar_2 <= x"00";
    
    case estado_actual is
      when ESTADO_LECTURA_ROM =>
        rom_addr <= std_logic_vector(to_unsigned(indice_dato, 4));
        
      when ESTADO_GUARDAR_RAM =>
        ram_addr_write <= std_logic_vector(to_unsigned(indice_dato, 4));
        ram_data_write <= rom_data;
        ram_we <= '1';
        
      when ESTADO_LEER_RAM =>
        ram_addr_read <= std_logic_vector(to_unsigned(indice_dato, 4));
        
      when ESTADO_MOSTRAR =>
        -- Mostrar los datos en los displays
        dato_mostrar_0 <= x"30";  -- Mostrar '0'
        dato_mostrar_1 <= x"31";  -- Mostrar '1'
        dato_mostrar_2 <= x"32";  -- Mostrar '2'
        
    end case;
  end process;

  -- Actualizar índice de dato en cada ciclo de reloj
  process(clk_sel, rst)
  begin
    if rst = '1' then
      indice_dato <= 0;
    elsif rising_edge(clk_sel) then
      if estado_actual = ESTADO_LECTURA_ROM or 
         estado_actual = ESTADO_GUARDAR_RAM or 
         estado_actual = ESTADO_LEER_RAM then
        if contador_estado = 0 then
          indice_dato <= indice_dato + 1;
        end if;
      end if;
    end if;
  end process;

end architecture;