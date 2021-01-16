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

		REG_ADDR: in std_logic_vector(5 downto 0);
		REG_VALUE_WRITE: in std_logic_vector(7 downto 0);
		REG_VALUE_READ: out std_logic_vector(7 downto 0);
		REG_RW: in std_logic; -- read - 0; write - 1;
		REG_STRB: in std_logic; -- do operation - 1;
		REG_DONE_STRB: out std_logic; -- operation done, result present in REG_VALUE_READ if any;
		REG_FAIL_STRB : out std_logic;

		RXCMD: out std_logic_vector(7 downto 0);
		RXCMD_STRB: out std_logic;

		ULPI_DATA_OUT: out std_logic_vector(7 downto 0);
		ULPI_DATA_OUT_STRB: out std_logic;
		ULPI_DATA_OUT_END: out std_logic;

		ULPI_PID_IN: in std_logic_vector(5 downto 0);
		ULPI_DATA_IN: in std_logic_vector(7 downto 0);
		ULPI_DATA_IN_STRB: in std_logic;
		ULPI_DATA_IN_STRB_STRB: out std_logic;
		ULPI_DATA_IN_END: in std_logic;

		RESETn: in std_logic;

		LED: out std_logic_vector(7 downto 0)
	);
end entity ULPI;

architecture ULPI_arch of ULPI is
signal USB_DATA_IN: std_logic_vector(7 downto 0);
signal USB_DATA_OUT: std_logic_vector(7 downto 0);

type state_type is (IDLE, TXCMD_PID, TXCMD_DATA, REG_WRITE_ADDR,
		    REG_WRITE_VALUE, REG_WRITE_STOP, REG_READ_ADDR,
		    REG_READ_VALUE, REG_READ_RESULT, READ_RXCMD, READ_USB);

signal state: state_type;
signal state_tmp: state_type;
signal REG_ADDR_REG, reg_addr_reg_temp : std_logic_vector(5 downto 0);
signal REG_VALUE_WRITE_REG, reg_value_write_reg_temp : std_logic_vector(7 downto 0);
begin
	USB_CS <= '1';


	process (USB_DIR, USB_DATA, USB_DATA_OUT) begin
		if (USB_DIR = '1') then
			USB_DATA_IN <= USB_DATA;
			USB_DATA <= "ZZZZZZZZ";
		else
			USB_DATA_IN <= (others => '0');
			USB_DATA <= USB_DATA_OUT;
		end if;
	end process;

	process(RESETn) begin
		if (RESETn = '0') then
			USB_RESET_n <= '0';
		else
			USB_RESET_n <= '1';
		end if;
	end process;

	process(USB_CLK, RESETn) begin
		if (RESETn = '0') then
			state <= IDLE;
			REG_ADDR_REG <= (others => '0');
			REG_VALUE_WRITE_REG <= (others => '0');

		elsif (falling_edge(USB_CLK)) then
			state <= state_tmp;
			REG_ADDR_REG <= reg_addr_reg_temp;
			REG_VALUE_WRITE_REG <= reg_value_write_reg_temp;
		end if;
	end process;

	process (state, RESETn, REG_ADDR_REG, REG_VALUE_WRITE_REG, USB_DATA_IN, USB_NXT, USB_DIR, REG_STRB, REG_RW, REG_VALUE_WRITE, REG_ADDR) begin
		USB_STP <= '0';
		REG_DONE_STRB <= '0';
		REG_VALUE_READ <= (others => '0');
		USB_DATA_OUT <= (others => '0');
		RXCMD <= (others => '0');
		RXCMD_STRB <= '0';
		REG_FAIL_STRB <= '0';
		state_tmp <= state;
		reg_value_write_reg_temp <= REG_VALUE_WRITE_REG;
		reg_addr_reg_temp <= REG_ADDR_REG;
		LED <= (others => '0');
		ULPI_DATA_OUT <= (others => '0');
		ULPI_DATA_OUT_STRB <= '0';
		ULPI_DATA_OUT_END <= '0';

		case state is
		when IDLE =>
			if (USB_DIR = '1') then
				state_tmp <= READ_RXCMD;
			elsif (REG_STRB = '1') then
				reg_addr_reg_temp <= REG_ADDR;
				if (REG_RW = '0') then
					state_tmp <= REG_READ_ADDR;
				else
					state_tmp <= REG_WRITE_ADDR;
					reg_value_write_reg_temp <= REG_VALUE_WRITE;
				end if;
			end if;
			LED <= "11111111";
		when REG_READ_ADDR =>
			USB_DATA_OUT <= "11" & REG_ADDR_REG;
			if (USB_DIR = '1') then
				state_tmp <= READ_RXCMD;
				REG_FAIL_STRB <= '1';
			elsif (USB_NXT = '1') then
				state_tmp <= REG_READ_VALUE;
			end if;
			LED <= "11111110";
		when REG_READ_VALUE =>
			if (USB_DIR = '1') then
				state_tmp <= REG_READ_RESULT;
			end if;
			LED <= "11111101";
		when REG_READ_RESULT =>
			REG_VALUE_READ <= USB_DATA_IN;
			REG_DONE_STRB <= '1';
			if (USB_DIR = '1') then
				state_tmp <= READ_RXCMD;
			else
				state_tmp <= IDLE;
			end if;
			LED <= "11111100";
		when REG_WRITE_ADDR =>
			USB_DATA_OUT <= "10" & REG_ADDR_REG;
			if (USB_DIR = '1') then
				state_tmp <= READ_RXCMD;
				REG_FAIL_STRB <= '1';
			elsif (USB_NXT = '1') then
				state_tmp <= REG_WRITE_VALUE;
			end if;
			LED <= "11111011";
		when REG_WRITE_VALUE =>
			USB_DATA_OUT <= REG_VALUE_WRITE_REG;

			if (USB_DIR = '1') then
				state_tmp <= READ_RXCMD;
				REG_FAIL_STRB <= '1';
			elsif (USB_NXT = '1') then
				state_tmp <= REG_WRITE_STOP;
			end if;

			LED <= "11111010";
		when REG_WRITE_STOP =>
			USB_STP <= '1';
			REG_DONE_STRB <= '1';

			if (USB_DIR = '1') then
				state_tmp <= READ_RXCMD;
			else
				state_tmp <= IDLE;
			end if;
			LED <= "11111001";
		when READ_RXCMD =>
			if (USB_DIR = '1' and USB_NXT = '0') then
				RXCMD <= USB_DATA_IN;
				RXCMD_STRB <= '1';
			elsif (USB_DIR = '1' and USB_NXT = '1') then
				ULPI_DATA_OUT <= USB_DATA_IN;
				ULPI_DATA_OUT_STRB <= '1';
				state_tmp <= READ_USB;
			elsif (USB_DIR = '0') then
				state_tmp <= IDLE;
			end if;
			LED <= "11111010";
		when READ_USB =>
			if (USB_DIR = '1' and USB_NXT = '0') then
				RXCMD <= USB_DATA_IN;
				RXCMD_STRB <= '1';
				if (USB_DATA_IN(5 downto 4) = "00") then
					ULPI_DATA_OUT_END <= '1';
					state_tmp <= READ_RXCMD;
				end if;
			elsif (USB_DIR = '1' and USB_NXT = '1') then
				ULPI_DATA_OUT <= USB_DATA_IN;
				ULPI_DATA_OUT_STRB <= '1';
			elsif (USB_DIR = '0') then
				state_tmp <= IDLE;
				ULPI_DATA_OUT_END <= '1';
			end if;
			LED <= "01010101";
		when others =>
		end case;
	end process;
end ULPI_arch;
