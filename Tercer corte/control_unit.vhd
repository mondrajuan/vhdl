library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
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
end entity control_unit;

architecture rtl of control_unit is
  type state_type is (FETCH, DECODE, FETCH_ADDR, EXECUTE);
  signal state, next_state : state_type;
  constant OPC_LD  : std_logic_vector(7 downto 0) := x"01";
  constant OPC_ST  : std_logic_vector(7 downto 0) := x"02";
  constant OPC_ADD : std_logic_vector(7 downto 0) := x"03";
  constant OPC_SUB : std_logic_vector(7 downto 0) := x"04";
  -- MODIFICADO: Se asinga el codigo 00 para permitir paso por la ALU usando R0
  constant OPC_AND : std_logic_vector(7 downto 0) := x"00"; 
  constant OPC_OR  : std_logic_vector(7 downto 0) := x"06";
  constant OPC_NOT : std_logic_vector(7 downto 0) := x"07";
  constant OPC_JMP : std_logic_vector(7 downto 0) := x"08";
begin
  process(clk, rst)
  begin
    if rst = '1' then
      state <= FETCH;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process;

  process(state, opcode)
  begin
    pc_inc     <= '0';
    pc_load    <= '0';
    ir_en      <= '0';
    addr_en    <= '0';
    reg_wen    <= '0';
    reg_src    <= '0';
    ram_wen    <= '0';
    alu_op     <= "000";
    next_state <= FETCH;

    case state is
      when FETCH =>
        ir_en      <= '1';
        pc_inc     <= '1';
        next_state <= DECODE;
      when DECODE =>
        if opcode = OPC_LD or opcode = OPC_ST or opcode = OPC_JMP then
          next_state <= FETCH_ADDR;
        else
          next_state <= EXECUTE;
        end if;
      when FETCH_ADDR =>
        addr_en    <= '1';
        pc_inc     <= '1';
        next_state <= EXECUTE;
      when EXECUTE =>
        case opcode is
          when OPC_LD =>
            reg_wen <= '1';
            reg_src <= '1';
            next_state <= FETCH;
          when OPC_ST =>
            ram_wen <= '1';
            next_state <= FETCH;
          when OPC_ADD =>
            alu_op  <= "000";
            reg_wen <= '1';
            reg_src <= '0';
            next_state <= FETCH;
          when OPC_SUB =>
            alu_op  <= "001";
            reg_wen <= '1';
            reg_src <= '0';
            next_state <= FETCH;
          when OPC_AND =>
            alu_op  <= "010";
            reg_wen <= '1';
            reg_src <= '0';
            next_state <= FETCH;
          when OPC_OR =>
            alu_op  <= "011";
            reg_wen <= '1';
            reg_src <= '0';
            next_state <= FETCH;
          when OPC_NOT =>
            alu_op  <= "100";
            reg_wen <= '1';
            reg_src <= '0';
            next_state <= FETCH;
          when OPC_JMP =>
            pc_load <= '1';
            next_state <= FETCH;
          when others =>
            next_state <= FETCH;
        end case;
    end case;
  end process;
end architecture rtl;