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
	component ULPI is
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

		ULPI_PID_IN: in std_logic_vector(5 downto 0);
		ULPI_DATA_IN: in std_logic_vector(7 downto 0);
		ULPI_DATA_IN_STRB: in std_logic;
		ULPI_DATA_IN_STRB_STRB: out std_logic;
		ULPI_DATA_IN_END: in std_logic;

		RESETn: in std_logic;

		LED : out std_logic_vector(7 downto 0)
	);
	end component;

signal REG_ADDR, ULPI_PID_IN: std_logic_vector(5 downto 0);
signal REG_VALUE_READ, REG_VALUE_WRITE, LED_REG, RXCMD, ULPI_DATA_OUT, RXCMD_REG: std_logic_vector(7 downto 0);
signal counter, ULPI_DATA_IN: std_logic_vector(7 downto 0);
signal REG_RW, REG_STRB, REG_DONE_STRB, RXCMD_STRB, ULPI_DATA_OUT_STRB, REG_FAIL_STRB: std_logic;
signal divider : std_logic_vector(19 downto 0);
signal dividerr : std_logic_vector(21 downto 0);
signal ULPI_DATA_IN_STRB, ULPI_DATA_IN_STRB_STRB, ULPI_DATA_IN_END: std_logic;

type state_type is (IDLE, REG_READ, REG_READ_WAIT, REG_WRITE, REG_WRITE_WAIT);
signal state: state_type;
begin
	ULPI_0 : ULPI
	port map (
		MAX10_CLK_50M => MAX10_CLK_50M,
		USB_CLK => USB_CLK,
		USB_DATA => USB_DATA,
		USB_NXT => USB_NXT,
		USB_DIR => USB_DIR,
		USB_STP => USB_STP,
		USB_CS => USB_CS,
		USB_RESET_n => USB_RESET_n,
		RESETn => RESETn,

		REG_ADDR => REG_ADDR,
		REG_VALUE_WRITE => REG_VALUE_WRITE,
		REG_VALUE_READ => REG_VALUE_READ,
		REG_RW => REG_RW,
		REG_STRB => REG_STRB,
		REG_DONE_STRB => REG_DONE_STRB,
		REG_FAIL_STRB => REG_FAIL_STRB,

		RXCMD => RXCMD,
		RXCMD_STRB => RXCMD_STRB,

		ULPI_DATA_OUT => ULPI_DATA_OUT,
		ULPI_DATA_OUT_STRB => ULPI_DATA_OUT_STRB,

		ULPI_PID_IN => ULPI_PID_IN,
		ULPI_DATA_IN => ULPI_DATA_IN,
		ULPI_DATA_IN_STRB => ULPI_DATA_IN_STRB,
		ULPI_DATA_IN_STRB_STRB => ULPI_DATA_IN_STRB_STRB,
		ULPI_DATA_IN_END => ULPI_DATA_IN_END
	);

	process(USB_CLK, RESETn) begin
	if (RESETn = '0') then
		state <= IDLE;
		LED_REG <= (others => '1');
		counter <= (others => '1');

		divider <= (others => '0');
		dividerr <= (others => '0');

	elsif (falling_edge(USB_CLK)) then
		REG_STRB <= '0';

		if (REG_FAIL_STRB = '1') then
			state <= IDLE;
		else
			if (ULPI_DATA_OUT_STRB = '1') then
				LED_REG <= "01010101";
			end if;

			case state is
			when IDLE =>
				if (dividerr /= "1111111111111111111111") then
					dividerr <= std_logic_vector(unsigned(dividerr) + 1);
				end if;
				if (dividerr = "1111111111111111111111") then
					state <= REG_READ;
				end if;
			when REG_READ =>
				REG_ADDR <= "010110";
				REG_RW <= '0';
				REG_STRB <= '1';
				state <= REG_READ_WAIT;
			when REG_READ_WAIT =>
				REG_STRB <= '1';
				if (REG_DONE_STRB = '1') then
					REG_STRB <= '0';
					state <= REG_WRITE;
--					LED_REG <= REG_VALUE_READ;
				end if;
			when REG_WRITE =>
				REG_ADDR <= "010110";
				REG_RW <= '1';
				REG_STRB <= '1';
				REG_VALUE_WRITE <= counter;
				if (unsigned(divider) = 0) then
					counter <= std_logic_vector(unsigned(counter) + 1);
				end if;
				divider <= std_logic_vector(unsigned(divider) + 1);
				state <= REG_WRITE_WAIT;
			when REG_WRITE_WAIT =>
				REG_STRB <= '1';
				if (REG_DONE_STRB = '1') then
					REG_STRB <= '0';
					state <= IDLE;
				end if;
			when others =>
				state <= IDLE;
			end case;
		end if;
	end if;
	end process;

	LED <= LED_REG;

end audiocard_arch;
