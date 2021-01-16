LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ULPI_tb is
end entity ULPI_tb;

architecture ULPI_tb_arch of ULPI_tb is

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

	RXCMD: out std_logic_vector(7 downto 0);
	RXCMD_STRB: out std_logic;

	ULPI_DATA_OUT: out std_logic_vector(7 downto 0);
	ULPI_DATA_OUT_STRB: out std_logic;

	ULPI_PID_IN: in std_logic_vector(5 downto 0);
	ULPI_DATA_IN: in std_logic_vector(7 downto 0);
	ULPI_DATA_IN_STRB: in std_logic;
	ULPI_DATA_IN_STRB_STRB: out std_logic;
	ULPI_DATA_IN_END: in std_logic;

	RESETn: in std_logic
);
end component;

signal MAX10_CLK_50M, USB_CLK, USB_NXT, USB_DIR, USB_STP, USB_CS, USB_RESET_n : std_logic := '0';
signal REG_RW, REG_STRB, REG_DONE_STRB, RXCMD_STRB, ULPI_DATA_OUT_STRB : std_logic := '0';
signal ULPI_DATA_IN_STRB, ULPI_DATA_IN_STRB_STRB, ULPI_DATA_IN_END : std_logic := '0';
signal RESETn : std_logic := '0';
signal USB_DATA, REG_VALUE_WRITE, REG_VALUE_READ, RXCMD, ULPI_DATA_OUT : std_logic_vector(7 downto 0) := (others => '0');
signal ULPI_DATA_IN, USB_DATA_OUT, USB_DATA_IN : std_logic_vector(7 downto 0) := (others => '0');
signal REG_ADDR, ULPI_PID_IN : std_logic_vector(5 downto 0) := (others => '0');

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

	process begin
		MAX10_CLK_50M <= '0';
		wait for 10 ns;
		MAX10_CLK_50M <= '1';
		wait for 10 ns;
	end process;

	process begin
		USB_CLK <= '0';
		wait for 8 ns; --should be 8.333ns, but 8 is also ok.
		USB_CLK <= '1';
		wait for 8 ns;
	end process;

	process (USB_DIR, USB_DATA_IN, USB_DATA) begin
		if (USB_DIR = '1') then
			USB_DATA_OUT <= (others => 'Z');
			USB_DATA <= USB_DATA_IN;
		else
			USB_DATA_OUT <= USB_DATA;
			USB_DATA <= (others => 'Z');
		end if;
	end process;

	process begin
		RESETn <= '0';
		wait for 31 ns;
		RESETn <= '1';
		wait for 16 ns;
		REG_ADDR <= "001100"; --lets read register 0b1100;
		REG_RW <= '0';
		REG_STRB <= '1';
		wait for 16 ns;
		REG_STRB <= '0';
		wait for 16 ns;
		assert USB_DATA = "11001100" report "Wrong USB_DATA" severity failure;
		wait for 16 ns;
		USB_NXT <= '1';
		wait for 16 ns;
		USB_NXT <= '0';
		USB_DIR <= '1';
		wait for 16 ns;
		USB_DATA_IN <= "01010101";
		USB_DIR <= '1';
		wait for 16 ns;
		assert REG_VALUE_READ = "01010101" severity failure;
		USB_DIR <= '0';
		wait for 32 ns;
		REG_ADDR <= "001100";
		REG_VALUE_WRITE <= "11110000";
		REG_RW <= '1';
		REG_STRB <= '1';
		wait for 16 ns;
		REG_STRB <= '0';
		REG_RW <= '0';
		wait for 16 ns;
		assert USB_DATA = "10001100" severity failure;
		wait for 16 ns;
		USB_NXT <= '1';
		wait for 16 ns;
		USB_NXT <= '0';
		wait for 16 ns;
		USB_NXT <= '1';
		wait for 16 ns;
		USB_NXT <= '0';
		wait;
	end process;

end ULPI_tb_arch;
