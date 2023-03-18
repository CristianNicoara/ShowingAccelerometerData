----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2022 07:03:21 PM
-- Design Name: 
-- Module Name: main - Behavioral
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

entity main is
Port ( 
    Clk : in std_logic;
    Rst : in std_logic;
    MISO : in std_logic;
    MOSI : out std_logic;
    SCLK : out std_logic;
    SS : out std_logic_vector(0 downto 0);
    Seg : out std_logic_vector(6 downto 0);
    sign : out std_logic;
    An : out std_logic_vector(7 downto 0)
);
end main;

architecture Behavioral of main is

signal Data : std_logic_vector(14 downto 0);
signal Clk4MHz : std_logic;

signal Read_debounce : std_logic;

signal x_data : std_logic_vector(4 downto 0);
signal y_data : std_logic_vector(4 downto 0);
signal z_data : std_logic_vector(4 downto 0);

begin

SPI_acceler2: entity WORK.mod_accelerometer port map (Clk => Clk, Rst => Rst, MISO => MISO, SCLK => SCLK,
                                                      MOSI => MOSI, SS => SS, x_data => x_data, y_data => y_data, z_data => z_data);


Data <= x_data & y_data & z_data;
--Data <= "111100011011110";
                                              
display: entity WORK.displ7seg port map (Clk => Clk, Rst => Rst, Data => Data, An => An, sign => sign, Seg => Seg);

end Behavioral;
