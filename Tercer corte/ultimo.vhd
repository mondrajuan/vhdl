library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ultimo is
  port (
    clk            : in  std_logic;
    switches       : in  std_logic_vector(2 downto 0);
    led_out        : out std_logic;
    ventilador_out : out std_logic
  );
end entity ultimo;

architecture behave of ultimo is

  component program_counter
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      pc_inc  : in  std_logic;
      pc_load : in  std_logic;
      data_in : in  std_logic_vector(7 downto 0);
      pc_out  : out std_logic_vector(7 downto 0)
    );
  end component;

  component instruction_register
    port (
      clk  : in  std_logic;
      rst  : in  std_logic;
      en   : in  std_logic;
      din  : in  std_logic_vector(7 downto 0);
      dout : out std_logic_vector(7 downto 0)
    );
  end component;

  component rom
    port (
      addr : in  std_logic_vector(7 downto 0);
      dout : out std_logic_vector(7 downto 0)
    );
  end component;

  component ram
    port (
      clk  : in  std_logic;
      rst  : in  std_logic;
      addr : in  std_logic_vector(7 downto 0);
      din  : in  std_logic_vector(7 downto 0);
      wen  : in  std_logic;
      dout : out std_logic_vector(7 downto 0)
    );
  end component;

  component banco_registros
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      addr_w  : in  std_logic_vector(1 downto 0);
      addr_r1 : in  std_logic_vector(1 downto 0);
      addr_r2 : in  std_logic_vector(1 downto 0);
      din     : in  std_logic_vector(7 downto 0);
      wen     : in  std_logic;
      dout1   : out std_logic_vector(7 downto 0);
      dout2   : out std_logic_vector(7 downto 0)
    );
  end component;

  component alu
    port (
      operand_a : in  std_logic_vector(7 downto 0);
      operand_b : in  std_logic_vector(7 downto 0);
      opcode    : in  std_logic_vector(2 downto 0);
      result    : out std_logic_vector(7 downto 0)
    );
  end component;

  component control_unit
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      opcode  : in  std_logic_vector(7 downto 0);
      pc_inc  : out std_logic;
      pc_load : out std_logic;
      ir_en   : out std_logic;
      addr_en : out std_logic;
      reg_wen : out std_logic;
      reg_src : out std_logic;
      ram_wen : out std_logic;
      alu_op  : out std_logic_vector(2 downto 0)
    );
  end component;

  signal rst_reg     : std_logic_vector(3 downto 0) := (others => '1');
  signal rst_interno : std_logic;

  signal pc_out       : std_logic_vector(7 downto 0);
  signal ir_out       : std_logic_vector(7 downto 0);
  signal addr_reg     : std_logic_vector(7 downto 0);
  signal rom_data     : std_logic_vector(7 downto 0);
  signal ram_data_out : std_logic_vector(7 downto 0);
  signal ram_addr     : std_logic_vector(7 downto 0);
  signal ram_data_in  : std_logic_vector(7 downto 0);
  signal reg_out1     : std_logic_vector(7 downto 0);
  signal reg_out2     : std_logic_vector(7 downto 0);
  signal reg_din      : std_logic_vector(7 downto 0);
  signal alu_result   : std_logic_vector(7 downto 0);
  signal bank_addr_w  : std_logic_vector(1 downto 0);
  signal bank_addr_r1 : std_logic_vector(1 downto 0);

  signal pc_inc  : std_logic;
  signal pc_load : std_logic;
  signal ir_en   : std_logic;
  signal addr_en : std_logic;
  signal reg_wen : std_logic;
  signal reg_src : std_logic;
  signal ram_wen : std_logic;
  signal alu_op  : std_logic_vector(2 downto 0);

  constant ADDR_ENTRADA : std_logic_vector(7 downto 0) := x"FF";
  constant ADDR_SALIDA  : std_logic_vector(7 downto 0) := x"FE";
  constant OPC_LD       : std_logic_vector(7 downto 0) := x"01";
  constant OPC_ST       : std_logic_vector(7 downto 0) := x"02";

  signal entrada_data : std_logic_vector(7 downto 0);
  signal salida_reg   : std_logic_vector(7 downto 0);

  signal modo          : std_logic;
  signal switch_led    : std_logic;
  signal switch_fan    : std_logic;
  
  -- Contador ampliado para 5 segundos reales en FPGA a 50MHz
  signal contador_auto : unsigned(27 downto 0);
  signal estado_auto   : std_logic_vector(1 downto 0);
  constant PERIODO_AUTO : unsigned(27 downto 0) := to_unsigned(250000000, 28);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      rst_reg <= rst_reg(2 downto 0) & '0';
    end if;
  end process;

  rst_interno <= rst_reg(3);

  modo       <= switches(2);
  switch_led <= switches(1);
  switch_fan <= switches(0);

  -- Multiplexor de hardware que inyecta manual o automatico al puerto FF
  entrada_data <= "000000" & switch_led & switch_fan when modo = '0' else
                  "000000" & estado_auto;

  pc_inst : program_counter
    port map (
      clk     => clk,
      rst     => rst_interno,
      pc_inc  => pc_inc,
      pc_load => pc_load,
      data_in => addr_reg,
      pc_out  => pc_out
    );

  ir_inst : instruction_register
    port map (
      clk  => clk,
      rst  => rst_interno,
      en   => ir_en,
      din  => rom_data,
      dout => ir_out
    );

  rom_inst : rom
    port map (
      addr => pc_out,
      dout => rom_data
    );

  process(clk, rst_interno)
  begin
    if rst_interno = '1' then
      addr_reg <= (others => '0');
    elsif rising_edge(clk) then
      if addr_en = '1' then
        addr_reg <= rom_data;
      end if;
    end if;
  end process;

  ram_addr    <= addr_reg;
  ram_data_in <= reg_out1;

  ram_inst : ram
    port map (
      clk  => clk,
      rst  => rst_interno,
      addr => ram_addr,
      din  => ram_data_in,
      wen  => ram_wen,
      dout => ram_data_out
    );

  bank_addr_w  <= "00" when ir_out = OPC_LD else ir_out(1 downto 0);
  bank_addr_r1 <= "00" when ir_out = OPC_ST else ir_out(3 downto 2);

  reg_din <= entrada_data when (reg_src = '1' and addr_reg = ADDR_ENTRADA) else
             ram_data_out  when (reg_src = '1')                              else
             alu_result;

  banco_inst : banco_registros
    port map (
      clk     => clk,
      rst     => rst_interno,
      addr_w  => bank_addr_w,
      addr_r1 => bank_addr_r1,
      addr_r2 => ir_out(5 downto 4),
      din     => reg_din,
      wen     => reg_wen,
      dout1   => reg_out1,
      dout2   => reg_out2
    );

  alu_inst : alu
    port map (
      operand_a => reg_out1,
      operand_b => reg_out2,
      opcode    => alu_op,
      result    => alu_result
    );

  control_inst : control_unit
    port map (
      clk     => clk,
      rst     => rst_interno,
      opcode  => ir_out,
      pc_inc  => pc_inc,
      pc_load => pc_load,
      ir_en   => ir_en,
      addr_en => addr_en,
      reg_wen => reg_wen,
      reg_src => reg_src,
      ram_wen => ram_wen,
      alu_op  => alu_op
    );

  process(clk, rst_interno)
  begin
    if rst_interno = '1' then
      salida_reg <= (others => '0');
    elsif rising_edge(clk) then
      if ram_wen = '1' and addr_reg = ADDR_SALIDA then
        salida_reg <= reg_out1;
      end if;
    end if;
  end process;

  led_out        <= salida_reg(1);
  ventilador_out <= salida_reg(0);

  process(clk, rst_interno)
  begin
    if rst_interno = '1' then
      contador_auto <= (others => '0');
      estado_auto   <= "00";
    elsif rising_edge(clk) then
      if modo = '1' then
        if contador_auto = PERIODO_AUTO - 1 then
          contador_auto <= (others => '0');
          estado_auto   <= std_logic_vector(unsigned(estado_auto) + 1);
        else
          contador_auto <= contador_auto + 1;
        end if;
      else
        contador_auto <= (others => '0');
        estado_auto   <= "00";
      end if;
    end if;
  end process;

end architecture behave;