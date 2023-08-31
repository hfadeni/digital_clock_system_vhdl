library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity digital_clock is
port( rst, clk_fpga: in std_logic;
		hex0, hex1, hex3, hex5: out std_logic_vector(6 downto 0);
		hex2, hex4: out std_logic_vector(7 downto 0)
		);
end entity digital_clock;

architecture count of digital_clock is
	component seg is
		port(bcd : in std_logic_vector(3 downto 0);
			  seven : out std_logic_vector(6 downto 0));
	end component seg;
	
	component point_off is
		port(bcd_off: in std_logic_vector(3 downto 0);
			  eight_off: out std_logic_vector(7 downto 0)
			  );
	end component point_off;
	
	component point_on is
		port(bcd_on: in std_logic_vector(3 downto 0);
			  eight_on: out std_logic_vector(7 downto 0)
			  );
	end component point_on;

	signal s_count, s_count1, s_count2, s_count3: std_logic_vector(3 downto 0);
	signal s_count4, s_count5: std_logic_vector(3 downto 0);
	signal s_seven, s_seven1, s_seven3, s_seven5: std_logic_vector(6 downto 0);
	signal s_eight2, s_on, s_off: std_logic_vector(7 downto 0);
	signal s_eight4, s8_on, s8_off: std_logic_vector(7 downto 0);
	
begin
	------------ Port maps to connect the components ------------------
	conv0: seg port map(bcd => std_logic_vector(s_count), seven => s_seven);
	conv1: seg port map(bcd => std_logic_vector(s_count1), seven => s_seven1);
	conv3: seg port map(bcd => std_logic_vector(s_count3), seven => s_seven3);
	conv5: seg port map(bcd => std_logic_vector(s_count5), seven => s_seven5);
	conv2_on: point_on port map(bcd_on => std_logic_vector(s_count2), eight_on => s_on);
	conv2_off: point_off port map(bcd_off => std_logic_vector(s_count2), eight_off => s_off);
	conv4_on: point_on port map(bcd_on => std_logic_vector(s_count4), eight_on => s8_on);
	conv4_off: point_off port map(bcd_off => std_logic_vector(s_count4), eight_off => s8_off);
	
	------------ Process for the counting sequences -------------------
	process(clk_fpga, rst)
	variable delay : integer range 0 to 100e6 := 0;
	variable update_count, point: std_logic := '0';
	begin
		if rising_edge(clk_fpga) then
			if delay >= 50e6 then
				delay := 0;
				update_count := '1';
				if point = '0' then
					point := '1';
				else
					point := '0';
				end if;
			else
				delay := delay + 1;
				update_count := '0';
			end if;
		end if;
		
		if rst = '0' then 
			s_count <= (others => '0');
			s_count1 <= (others => '0');
			s_count2 <= (others => '0');
			s_count3 <= (others => '0');
			s_count4 <= (others => '0');
			s_count5 <= (others => '0');
		elsif rising_edge(clk_fpga) then
			if update_count = '1' then
				if s_count = "1001" then
					s_count <= (others=>'0');
					if s_count1 = "1001" then
						s_count1 <= (others=>'0');
					else
						s_count1 <= std_logic_vector(unsigned(s_count1) + 1);
					end if;
				elsif s_count1 = "0110" and s_count = "0000" then
					s_count <= (others => '0');
					s_count1 <= (others => '0');
					if s_count2 = "1001" then
						s_count2 <= (others => '0');
						if s_count3 = "0101" then
							s_count3 <= (others => '0');
						else
							s_count3 <= std_logic_vector(unsigned(s_count3) + 1);
						end if;
					else
						s_count2 <= std_logic_vector(unsigned(s_count2) + 1);
					end if;
				elsif s_count3 = "0101" and s_count2 = "0000" then
					s_count2 <= (others => '0');
					s_count3 <= (others => '0');
					if s_count5 = "0010" and s_count4 = "0011" then
						s_count4 <= (others => '0');
						s_count5 <= (others => '0');
					elsif s_count4 = "1001" then
						s_count4 <= (others => '0');
						if s_count5 = "0101" then
							s_count5 <= (others => '0');
						else
							s_count5 <= std_logic_vector(unsigned(s_count5) + 1);
						end if;
					else
						s_count4 <= std_logic_vector(unsigned(s_count4) + 1);
					end if;
				else
					s_count <= std_logic_vector(unsigned(s_count) + 1);
				end if;
				
			end if;
			if point = '0' then
				s_eight2 <= s_on; 
				s_eight4 <= s8_on;
			else
				s_eight2 <= s_off;
				s_eight4 <= s8_off;
			end if;
		end if;
	end process;
	
	------------ Output to the LEDs and the HEX displays ----------------
	hex0 <= s_seven;
	hex1 <= s_seven1;
	hex2 <= s_eight2;
	hex3 <= s_seven3;
	hex4 <= s_eight4; 
	hex5 <= s_seven5;
end architecture count;

library ieee;
use ieee.std_logic_1164.all;

entity seg is
port(bcd : in std_logic_vector(3 downto 0);
	 seven : out std_logic_vector(6 downto 0));
end entity seg;

architecture decode of seg is
begin
	with bcd select
		seven <= "1000000" when "0000",
					"1111001" when "0001",
					"0100100" when "0010",
					"0110000" when "0011",
					"0011001" when "0100",
					"0010010" when "0101",
					"0000010" when "0110",
					"1111000" when "0111",
					"0000000" when "1000",
					"0011000" when "1001",
					"0000110" when others;
end architecture decode;

library ieee;
use ieee.std_logic_1164.all;

entity point_on is
	port(bcd_on: in std_logic_vector(3 downto 0);
		  eight_on: out std_logic_vector(7 downto 0)
		  );
end entity point_on;

architecture behaviour of point_on is
begin
	with bcd_on select
		eight_on <= "01000000" when "0000",
					"01111001" when "0001",
					"00100100" when "0010",
					"00110000" when "0011",
					"00011001" when "0100",
					"00010010" when "0101",
					"00000010" when "0110",
					"01111000" when "0111",
					"00000000" when "1000",
					"00011000" when "1001",
					"00000110" when others;
end behaviour;

library ieee;
use ieee.std_logic_1164.all;

entity point_off is
	port(bcd_off: in std_logic_vector(3 downto 0);
		  eight_off: out std_logic_vector(7 downto 0)
		  );
end entity point_off;

architecture behaviour of point_off is
begin
	with bcd_off select
		eight_off <= "11000000" when "0000",
					"11111001" when "0001",
					"10100100" when "0010",
					"10110000" when "0011",
					"10011001" when "0100",
					"10010010" when "0101",
					"10000010" when "0110",
					"11111000" when "0111",
					"10000000" when "1000",
					"10011000" when "1001",
					"10000110" when others;
end behaviour;