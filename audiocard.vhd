LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity audiocard is
	port (
		MAX10_CLK_50M : in std_logic;
		USB_CLK: in std_logic;
		USB_DATA : inout std_logic_vector(7 downto 0);
		USB_NXT : in std_logic;
		USB_DIR : in std_logic;
		USB_STP : out std_logic;
		USB_CS : out std_logic;
		USB_RESET_n: out std_logic;
		LED: out std_logic_vector(7 downto 0);
		RESETn: in std_logic
	);
end entity audiocard;

architecture audiocard_arch of audiocard is
signal USB_CLK_NEG: std_logic;
signal USB_DATA_IN: std_logic_vector(7 downto 0);
signal USB_DATA_OUT: std_logic_vector(7 downto 0);
signal state: std_logic_vector(3 downto 0);
signal state_tmp: std_logic_vector(3 downto 0);
begin
	USB_CLK_NEG <= not(USB_CLK);
	USB_CS <= '1';


	process (USB_DIR, USB_DATA, USB_DATA_OUT, USB_DATA_IN) begin
		if (USB_DIR = '1') then
			USB_DATA_IN <= USB_DATA;
			USB_DATA <= "ZZZZZZZZ";
		else
			USB_DATA_IN <= (others => '0');
			USB_DATA <= USB_DATA_OUT;
		end if;
	end process;

	process(MAX10_CLK_50M) begin
	if (rising_edge(MAX10_CLK_50M)) then
		if (RESETn = '0') then
			USB_RESET_n <= '0';
		else
			USB_RESET_n <= '1';
		end if;
	end if;
	end process;

	process(USB_CLK_NEG) begin
	if (rising_edge(USB_CLK_NEG)) then
		if (RESETn = '0') then
			LED <= "11110000";
			state <= (others => '0');
			USB_DATA_OUT <= (others => '0');
		else
			USB_STP <= '0';

			case state is
			when "0000" =>
				if (USB_DIR = '0') then
					USB_DATA_OUT <= "10010110";
					if (USB_NXT = '1') then
						USB_DATA_OUT <= "10101010";
						state <= "0001";
					end if;
				end if;
			when "0001" =>
				if (USB_DIR = '0') then
					USB_DATA_OUT <= "10101010";
					if (USB_NXT = '1') then
						state <= "0010";
					end if;
				else
					state <= "0000";
				end if;
			when "0010" =>
				if (USB_DIR = '0') then
					USB_DATA_OUT <= (others => '0');
					if (USB_NXT = '0') then
						USB_STP <= '1';
						state <= "0011";
					end if;
				else
					state <= "0000";
				end if;
			when "0011" =>
				if (USB_DIR = '0') then
					USB_DATA_OUT <= "11010110";
					if (USB_NXT = '1') then
						state <= "0100";
					end if;
				else
					state <= "0011";
				end if;
			when "0100" =>
				if (USB_DIR = '1') then
					state <= "0101";
				end if;
			when "0101" =>
				if (USB_DIR = '1') then
					LED <= USB_DATA_IN;
				end if;
				state <= "0000";
			when others =>
				state <= "0000";
			end case;
		end if;
	end if;
	end process;
end audiocard_arch;