----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.01.2023 22:40:05
-- Design Name: 
-- Module Name: mod_accelerometer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mod_accelerometer is
generic (
    clk_freq : integer := 100;               --frecventa ceasului de sistem in MHz
    data_rate : std_logic_vector := "011";  --rata de date pt configurarea accelerometrului.
    data_range : std_logic_vector := "00"); --intervalul de date pt configurarea accelerometrului.
Port ( 
    Clk : in std_logic;
    Rst : in std_logic;
    MISO : in std_logic;
    SCLK : out std_logic;
    MOSI : out std_logic;
    SS : out std_logic_vector(0 downto 0);
    x_data : out std_logic_vector(4 downto 0);
    y_data : out std_logic_vector(4 downto 0);
    z_data : out std_logic_vector(4 downto 0)
);
end mod_accelerometer;

architecture Behavioral of mod_accelerometer is

type states is (start, pause, configure, read_data, output_result);
signal state : states := start;
signal param : integer range 0 to 3;
signal parameter_addr : std_logic_vector(5 downto 0);
signal parameter_data : std_logic_vector(7 downto 0);
signal spi_busy_previous : std_logic;
signal spi_busy : std_logic;
signal spi_En : std_logic;
signal spi_cont_mod : std_logic;
signal spi_tx_data : std_logic_vector(7 downto 0);
signal spi_rx_data : std_logic_vector(7 downto 0);
signal x_data_int : std_logic_vector(15 downto 0);
signal y_data_int : std_logic_vector(15 downto 0);
signal z_data_int : std_logic_vector(15 downto 0);

begin

SPI_master1: entity WORK.SPI_master generic map (n => 8, nr_slaves => 1)
                port map (Clk => Clk, Rst => Rst, En => spi_En, cpol => '0', 
                    cpha => '0', cont_mod => spi_cont_mod, clk_div => clk_freq/16, 
                    addr => 0, tx_data => spi_tx_data, MISO => MISO, SCLK => SCLK,
                    SS => SS, MOSI => MOSI, busy => spi_busy, rx_data => spi_rx_data);

process(Clk)
    variable cnt : integer := 0;
begin
    if (Rst = '0') then
        spi_busy_previous <= '0';
        spi_En <= '0';
        spi_cont_mod <= '0';
        spi_tx_data <= (others => '0');
        x_data <= (others => '0');
        y_data <= (others => '0');
        z_data <= (others => '0');
        state <= start;
    elsif rising_edge(Clk) then
        case state is 
            when start =>
                cnt := 0;
                param <= 0;
                state <= pause;
            
            when pause =>
                if spi_busy = '0' then
                    if (cnt < clk_freq/5) then
                        cnt := cnt + 1;
                        state <= pause;
                    else
                        cnt := 0;
                        case param is
                            when 0 =>
                                param <= param + 1;
                                parameter_addr <= "101100";
                                parameter_data <= data_range & "010" & data_rate;
                                state <= configure;
                            when 1 =>
                                param <= param + 1;
                                parameter_addr <= "101101";
                                parameter_data <= "00000010";
                                state <= configure;
                            when 2 =>
                                state <= read_data;
                            when others => null;                           
                        end case;
                    end if;
                end if;
            
            when configure =>
                spi_busy_previous <= spi_busy;
                if (spi_busy_previous = '1' and  spi_busy = '0') then
                    cnt := cnt + 1;
                end if;
                case cnt is
                    when 0 => 
                        if (spi_busy = '0') then
                            spi_cont_mod <= '1';
                            spi_En <= '1';
                            spi_tx_data <= "00001010";
                        else
                            spi_tx_data <= "00" & parameter_addr;
                        end if;
                    when 1 => 
                        spi_tx_data <= parameter_data;
                    when 2 =>
                        spi_cont_mod <= '0';
                        spi_en <= '0';
                        cnt := 0;
                        state <= pause;
                    when others => null;
                end case;
            
            when read_data =>
                spi_busy_previous <= spi_busy;
                if (spi_busy_previous = '1' and spi_busy = '0') then
                    cnt := cnt + 1;
                end if;
                case cnt is
                    when 0 => 
                        if spi_busy = '0' then
                            spi_cont_mod <= '1';
                            spi_En <= '1';
                            spi_tx_data <= "00001011";
                        else
                            spi_tx_data <= "00001110";
                        end if;
                    when 1 => 
                        spi_tx_data <= "00000000";
                    when 3 => 
                        x_data_int(7 downto 0) <= spi_rx_data;
                    when 4 =>
                        x_data_int(15 downto 8) <= spi_rx_data;
                    when 5 => 
                        y_data_int(7 downto 0) <= spi_rx_data;
                    when 6 => 
                        y_data_int(15 downto 8) <= spi_rx_data;
                    when 7 => 
                        spi_cont_mod <= '0';
                        spi_En <= '0';
                        z_data_int(7 downto 0) <= spi_rx_data;
                    when 8 => 
                        z_data_int(15 downto 8) <= spi_rx_data;
                        cnt := 0;
                        state <= output_result;
                    when others => null; 
                end case;
                
            when output_result =>
                x_data <= x_data_int(11 downto 7);-- & x_data_int(3 downto 0);
                y_data <= y_data_int(11 downto 7);-- & y_data_int(3 downto 0);
                z_data <= z_data_int(11 downto 7);-- & z_data_int(3 downto 0);
                state <= pause;
            
            when others => 
                state <= start;
        end case;
    end if;
end process;

end Behavioral;
