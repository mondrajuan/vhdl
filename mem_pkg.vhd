library ieee;
use ieee.std_logic_1164.all;

package mem_pkg is
    -- Component declarations
    component divisor_1Hz
        port (
            clk : in std_logic;
            reset : in std_logic;
            clk_out : out std_logic
        );
    end component;
    
    -- Additional declarations as necessary
    -- ...

end package mem_pkg;