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
		LED: out std_logic_vector(7 downto 0);

		REG_ADDR: in std_logic_vector(5 downto 0);
		REG_VALUE_WRITE: in std_logic_vector(7 downto 0);
		REG_VALUE_READ: out std_logic_vector(7 downto 0);
		REG_RW: in std_logic; -- read - 0; write - 1;
		REG_STRB: in std_logic; -- do operation - 1;
		REG_DONE_STRB: out std_logic; -- operation done, result present in REG_VALUE_READ if any;
		RESETn: in std_logic
	);
	end component;

signal REG_ADDR: std_logic_vector(5 downto 0);
signal REG_VALUE_READ, REG_VALUE_WRITE, LED_REG: std_logic_vector(7 downto 0);
signal REG_RW, REG_STRB, REG_DONE_STRB, USB_CLK_NEG: std_logic;
signal state: std_logic;
begin
	USB_CLK_NEG <= not(USB_CLK);

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
		LED => open,
		RESETn => RESETn,

		REG_ADDR => REG_ADDR,
		REG_VALUE_WRITE => REG_VALUE_WRITE,
		REG_VALUE_READ => REG_VALUE_READ,
		REG_RW => REG_RW,
		REG_STRB => REG_STRB,
		REG_DONE_STRB => REG_DONE_STRB
	);

	process(USB_CLK_NEG, RESETn) begin
	if (RESETn = '0') then
		LED_REG <= (others => '0');
		state <= '0';
	elsif (rising_edge(USB_CLK_NEG)) then
		if (state = '0') then
			REG_ADDR <= "010110";
			REG_RW <= '1';
			REG_STRB <= '1';
			REG_VALUE_WRITE <= "01011010";
			if (REG_DONE_STRB = '1') then
				state <= '1';
				REG_STRB <= '0';
			end if;
		else
			REG_ADDR <= "010110";
			REG_RW <= '0';
			REG_STRB <= '1';
			if (REG_DONE_STRB = '1') then
				LED_REG <= REG_VALUE_READ;
				state <= '0';
				REG_STRB <= '0';
			end if;
		end if;
	end if;
	end process;

	LED <= LED_REG;

end audiocard_arch;
