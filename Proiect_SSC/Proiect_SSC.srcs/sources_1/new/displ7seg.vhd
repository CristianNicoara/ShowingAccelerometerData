library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity displ7seg is
   Port ( Clk  : in  STD_LOGIC;
          Rst  : in  STD_LOGIC;
          Data : in  STD_LOGIC_VECTOR (14 downto 0); 
          An   : out STD_LOGIC_VECTOR (7 downto 0); 
                 -- semnale pentru anozi (active in 0 logic)
          sign : out std_logic; -- Seg[7]
          Seg  : out STD_LOGIC_VECTOR (6 downto 0)); 
                 -- semnale pentru segmentele (catozii) cifrei active
end displ7seg;

architecture Behavioral of displ7seg is

constant CLK_RATE  : INTEGER := 100_000_000;  -- frecventa semnalului Clk
constant CNT_100HZ : INTEGER := 2**20;        -- divizor pentru rata de
                                              -- reimprospatare de ~100 Hz
 -- divizor pentru 500 ms
signal Count       : INTEGER range 0 to CNT_100HZ - 1 := 0;
signal CountVect   : STD_LOGIC_VECTOR (19 downto 0) := (others => '0');
signal LedSel      : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
signal Digit1      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit2      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit3      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit4      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit5      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit6      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit7      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Digit8      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

signal sign_x, sign_y, sign_z : std_logic;
signal data_x, data_y, data_z : std_logic_vector(3 downto 0);
signal x_10, x_1, y_10, y_1, z_10, z_1 : std_logic_vector(3 downto 0);

function HEX2SSEG (Hex : in STD_LOGIC_VECTOR (3 downto 0))
                  return STD_LOGIC_VECTOR is
   variable Sseg : STD_LOGIC_VECTOR (6 downto 0);
begin
   case Hex is
      when "0000" => Sseg := "1000000";  -- 0
      when "0001" => Sseg := "1111001";  -- 1
      when "0010" => Sseg := "0100100";  -- 2
      when "0011" => Sseg := "0110000";  -- 3
      when "0100" => Sseg := "0011001";  -- 4
      when "0101" => Sseg := "0010010";  -- 5
      when "0110" => Sseg := "0000010";  -- 6
      when "0111" => Sseg := "1111000";  -- 7
      when "1000" => Sseg := "0000000";  -- 8
      when "1001" => Sseg := "0010000";  -- 9
      when "1010" => Sseg := "0001000";  -- A
--      when "1011" => Sseg := "10000011";  -- b
--      when "1100" => Sseg := "11000110";  -- C
--      when "1101" => Sseg := "10100001";  -- d
--      when "1110" => Sseg := "10000110";  -- E
--      when "1111" => Sseg := "10001110";  -- F
      when others => Sseg := "1111111";
   end case;
   return Sseg;
end function HEX2SSEG;

begin

   --Scoatem bitii de semn din datele accelerometrului
   sign_x <= Data(14);
   sign_y <= Data(9);
   sign_z <= Data(4);
   
   --Scoatem datele pentru fiecare axa
   data_x <= Data(13 downto 10);
   data_y <= Data(8 downto 5);
   data_z <= Data(3 downto 0);
   
   --Conversia din binar in BCD
   x_10 <= "0000" when data_x = "0000" else CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_x) / 10, 4);
   x_1 <= "0000" when data_x = "0000" else CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_x) mod 10, 4);
   y_10 <= "0000" when data_y = "0000" else CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_y) / 10, 4);
   y_1 <= "0000" when data_y = "0000" else CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_y) mod 10, 4);
   z_10 <= "0000" when data_z = "0000" else CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_z) / 10, 4);
   z_1 <= "0000" when data_z = "0000" else CONV_STD_LOGIC_VECTOR(CONV_INTEGER(data_z) mod 10, 4);

   -- Proces pentru divizarea frecventei ceasului
   div_clk: process (Clk)
   begin
      if RISING_EDGE (Clk) then
         if (Rst = '0') then
            Count <= 0;
         elsif (Count = CNT_100HZ - 1) then
            Count <= 0;
         else
            Count <= Count + 1;
         end if;
      end if;
   end process div_clk;

   CountVect <= CONV_STD_LOGIC_VECTOR (Count, 20);
   LedSel <= CountVect (19 downto 17);


   -- Date pentru segmentele fiecarei cifre
--   Digit8 <= HEX2SSEG(Data (3 downto 0));
--   Digit7 <= HEX2SSEG(Data (7 downto 4));
--   Digit6 <= HEX2SSEG(Data (11 downto 8));
--   Digit5 <= HEX2SSEG(Data (15 downto 12));
--   Digit4 <= HEX2SSEG(Data (19 downto 16));
--   Digit3 <= HEX2SSEG(Data (23 downto 20));
--   Digit2 <= HEX2SSEG(Data (27 downto 24));
--   Digit1 <= HEX2SSEG(Data (31 downto 28));

   -- Semnal pentru selectarea cifrei active (anozi)
   An <= "11111110" when LedSel = "000" else
         "11111101" when LedSel = "001" else
         "11111011" when LedSel = "010" else
         "11110111" when LedSel = "011" else
         "11101111" when LedSel = "100" else
         "11011111" when LedSel = "101" else
         "10111111" when LedSel = "110" else
         "01111111" when LedSel = "111" else
         "11111111";

   -- Semnal pentru segmentele cifrei active (catozi)
--   Seg <= Digit8 when LedSel = "000" else
--          Digit7 when LedSel = "001" else
--          Digit6 when LedSel = "010" else
--          Digit5 when LedSel = "011" else
--          Digit4 when LedSel = "100" else
--          Digit3 when LedSel = "101" else
--          Digit2 when LedSel = "110" else
--          Digit1 when LedSel = "111" else
--          x"FF";
     process(LedSel)
     begin
        case LedSel is
            when "000" => if sign_z = '1' then
                            sign <= '0';
                          else
                            sign <= '1';  
                          end if;
                          Seg <= HEX2SSEG(z_1);
            when "001" => sign <= '1';
                          Seg <= HEX2SSEG(z_10);
            when "010" => sign <= '1';
                          Seg <= "1111111";
            when "011" => if sign_y = '1' then
                            sign <= '0';
                          else
                            sign <= '1';  
                          end if;
                          Seg <= HEX2SSEG(y_1);
            when "100" => sign <= '1';
                          Seg <= HEX2SSEG(y_10);
            when "101" => sign <= '1';
                          Seg <= "1111111";
            when "110" => if sign_x = '1' then
                            sign <= '0';
                          else
                            sign <= '1';  
                          end if;
                          Seg <= HEX2SSEG(x_1);
            when "111" => sign <= '1';
                          Seg <= HEX2SSEG(x_10);
            when others => sign <= '1';
                           Seg <= "1111111";                            
        end case;
     end process;

end Behavioral;