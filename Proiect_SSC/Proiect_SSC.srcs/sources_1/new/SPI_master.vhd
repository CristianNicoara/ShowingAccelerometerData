----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/02/2022 09:19:05 PM
-- Design Name: 
-- Module Name: SPI_master - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_master is
    generic (n : integer := 2;
             nr_slaves : integer := 4);
    port (
    Clk : in std_logic;                             --ceasul de sistem
    Rst : in std_logic;                             --reset asincron
    En : in std_logic;                              --initializarea transactiei
    CPol : in std_logic;                            --polaritatea ceasului
    CPha : in std_logic;                            --faza ceasului
    cont_mod : in std_logic;                        --comanda pentru modul name
    clk_div : in integer;                           --cicluri de ceas de sistem pt 1/2 din sclk
    addr : in integer;                              --adresa slave-ului
    tx_data: in std_logic_vector(n-1 downto 0);     --date pentru transmitere
    MISO : in std_logic;                            --master in, slave out
    SCLK : out std_logic;                            --ceas pentru spi
    SS : out std_logic_vector(nr_slaves-1 downto 0); --slave select
    MOSI : out std_logic;                           --master out, slave in
    busy : out std_logic;                           --ocupat / semnal cand sunt datele gata
    rx_data : out std_logic_vector(n-1 downto 0)    --datele primite
    );
end SPI_master;

architecture Behavioral of SPI_master is

    type states is (ready, execute);
    signal state : states; --starea curenta
    signal slave : integer; --slave-ul curent selectat
    signal clk_ratio : integer; --clk_div curent   
    signal count : integer;
    signal clk_toggles : integer range 0 to n*2 + 1; --numara comutarile spi clock
    signal assert_data : std_logic; --'1' este comutarea sclk tx,'0' este cmoutarea sclk rx
    signal continue    : std_logic; --flag pentru a continua tranzactia
    signal rx_buffer   : std_logic_vector(n-1 downto 0); --buffer pt date de primire
    signal tx_buffer   : std_logic_vector(n-1 downto 0); --buffer pt date de trimitere
    signal last_bit_rx : integer range 0 to n*2;         --locatia ultimuluii bit din rx
    signal SCLK_aux : std_logic;
    signal SS_aux : std_logic_vector(nr_slaves - 1 downto 0);

begin
    
    process(Clk, Rst)
    begin
        if Rst = '0' then --resetare
            busy <= '1'; 
            SS_aux <= (others => '1'); --deselectarea slave
            MOSI <= 'Z';
            rx_data <= (others => '0');
            state <= ready;
        elsif rising_edge(Clk) then
            case state is
                when ready => 
                    busy <= '0';
                    SS_aux <= (others => '1');
                    MOSI <= 'Z';
                    continue <= '0';
                    --SCLK <= CPol;
                    if En = '1' then
                        busy <= '1';
                        if addr < nr_slaves then    -- validare slave
                            slave <= addr; --selectia slave-ului
                        else
                            slave <= 0; --selecteaza primul slave
                        end if;
                        if clk_div = 0 then
                            clk_ratio <= 1;
                            count <= 1;
                        else
                            clk_ratio <= clk_div;
                            count <= clk_div;
                        end if;
                        SCLK_aux <= CPol;
                        assert_data <= not CPha;
                        tx_buffer <= tx_data;
                        clk_toggles <= 0;
                        last_bit_rx <= n*2 + CONV_INTEGER(CPha) - 1;
                        state <= execute;
                    else
                        state <= ready;
                    end if;
                    
                when execute =>
                    busy <= '1';
                    SS_aux(slave) <= '0';
                    
                    if count = clk_ratio then
                        count <= 1;
                        assert_data <= not assert_data;
                        if (clk_toggles = n*2 + 1) then
                            clk_toggles <= 0;
                        else
                            clk_toggles <= clk_toggles + 1;
                        end if;
                        
                        if (clk_toggles <= n*2 and SS_aux(slave) = '0') then
                            SCLK_aux <= not SCLK_aux;
                        end if;
                        
                        if (assert_data = '0' and clk_toggles < last_bit_rx + 1 and SS_aux(slave) = '0') then
                            rx_buffer <= rx_buffer(n-2 downto 0) & miso;
                        end if;
                        
                        if (assert_data = '1' and clk_toggles < last_bit_rx) then
                            MOSI <= tx_buffer(n-1);
                            tx_buffer <= tx_buffer(n-2 downto 0) & '0';
                        end if;
                        
                        if (clk_toggles = last_bit_rx and cont_mod = '1') then
                            tx_buffer <= tx_data;
                            clk_toggles <= last_bit_rx - n * 2 + 1;
                            continue <= '1';
                        end if;
                        
                        if (continue = '1') then
                            continue <= '0';
                            busy <= '0';
                            rx_data <= rx_buffer;
                        end if;
                        
                        if ((clk_toggles = n*2 + 1) and cont_mod = '0') then
                            busy <= '0';
                            SS_aux <= (others => '1');
                            MOSI <= 'Z';
                            rx_data <= rx_buffer;
                            state <= ready;
                        else
                            state <= execute;
                        end if;
                    else
                        count <= count + 1;
                        state <= execute; 
                    end if;
            end case;
        end if;
    end process;
    
    SCLK <= SCLK_aux;
    SS <= SS_aux;
end Behavioral;