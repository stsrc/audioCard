LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ULPI is
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

		REG_ADDR: in std_logic_vector(5 downto 0);
		REG_VALUE_WRITE: in std_logic_vector(7 downto 0);
		REG_VALUE_READ: out std_logic_vector(7 downto 0);
		REG_RW: in std_logic; -- read - 0; write - 1;
		REG_STRB: in std_logic; -- do operation - 1;
		REG_DONE_STRB: out std_logic; -- operation done, result present in REG_VALUE_READ if any;

		RESETn: in std_logic
	);
end entity ULPI;

architecture ULPI_arch of ULPI is
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
			state <= (others => '0');
			LED <= (others => '0');
		else
			LED <= (others => '0');
			state <= state_tmp;
		end if;
	end if;
	end process;

	process (state, USB_DATA_IN, REG_ADDR, REG_VALUE_WRITE, USB_DIR, REG_STRB, REG_RW, USB_DIR, USB_NXT) begin
		USB_DATA_OUT <= (others => '0');
		USB_STP <= '0';
		REG_VALUE_READ <= (others => '0');
		REG_DONE_STRB <= '0';
		state_tmp <= state;

		case state is
			when "0000" =>
				if (USB_DIR = '0') then
					if (REG_STRB = '1') then
						if (REG_RW = '1') then
							state_tmp <= "0001";
						else
							state_tmp <= "1001";
						end if;
					end if;
				end if;
			when "0001" => -- reg addr
				USB_DATA_OUT <= "10" & REG_ADDR;

				if (USB_DIR = '0') then
					if (USB_NXT = '1') then
						state_tmp <= "0010";
					end if;
				else
					state_tmp <= "0000";
				end if;


			when "0010" => -- reg value
				USB_DATA_OUT <= REG_VALUE_WRITE;

				if (USB_DIR = '0') then
					if (USB_NXT = '1') then
						state_tmp <= "0011";
					end if;
				else
					state_tmp <= "0000";
				end if;
			when "0011" => -- reg stp
				USB_STP <= '1';
				REG_DONE_STRB <= '1';

				if (USB_DIR = '0') then
					if (USB_NXT = '0') then
						state_tmp <= "0000";
					end if;
				else
					state_tmp <= "0000";
				end if;

			when "1001" => -- reg addr
				USB_DATA_OUT <= "11" & REG_ADDR;
				if (USB_DIR = '0') then
					if (USB_NXT = '1') then
						state_tmp <= "1010";
					end if;
				else
					state_tmp <= "0000";
				end if;
			when "1010" => -- reg addr
				USB_DATA_OUT <= "11" & REG_ADDR;
				if (USB_DIR = '1') then
					state_tmp <= "1011";
				end if;
			when "1011" => -- reg result
				REG_VALUE_READ <= USB_DATA_IN;
				REG_DONE_STRB <= '1';
				state_tmp <= "0000";
			when others =>
				state_tmp <= "0000";
		end case;
	end process;
end ULPI_arch;
