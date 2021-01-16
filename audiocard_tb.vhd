LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity audiocard_tb is
end entity audiocard_tb;

architecture audiocard_tb_arch of audiocard_tb is

component audiocard is
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
	RESETn: in std_logic;

	UART_TXD : out std_logic;
	UART_RXD : in std_logic
);
end component;

signal MAX10_CLK_50M, USB_CLK : std_logic := '0';
signal USB_DATA, USB_DATA_IN, USB_DATA_OUT, LED : std_logic_vector(7 downto 0) := (others => '0');
signal USB_NXT, USB_DIR, USB_STP, USB_CS, USB_RESET_n, RESETn : std_logic := '0';
signal UART_TXD, UART_RXD: std_logic := '0';

begin

	audiocard_0 : audiocard
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
		LED => LED,
		UART_TXD => UART_TXD,
		UART_RXD => UART_RXD
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
		wait for 32 ns;
		RESETn <= '1';
		wait for 16 ns;
		USB_DIR <= '1';
		wait for 16 ns;
		USB_DATA_IN <= "01011010";
		wait for 16 ns;
		USB_DIR <= '0';
		USB_DATA_IN <= (others => '0');
		wait for 16 ns;
		USB_DIR <= '1';
		wait for 16 ns;
		USB_DATA_IN <= "10100101";
		wait for 16 ns;
		USB_DIR <= '0';
		USB_DATA_IN <= (others => '0');
		wait for 16 ns;
		wait for 16 ns;
		USB_NXT <= '1';
		wait for 16 ns;
		USB_NXT <= '0';
		USB_DIR <= '1';
		wait for 16 ns;
		USB_DATA_IN <= "11000011";
		wait for 16 ns;
		USB_DIR <= '0';
		USB_DATA_IN <= (others => '0');
		wait for 32 ns;
		USB_DIR <= '1';
		wait for 16 ns;
		example_loop: for i in 0 to 64 loop
			USB_NXT <= '1';
			USB_DATA_IN <= std_logic_vector(unsigned(USB_DATA_IN) + 1);
			wait for 16 ns;
		end loop example_loop;
		USB_NXT <= '0';
		wait for 16 ns;
		USB_DIR <= '0';
		wait for 16 ns;
		wait;
	end process;

end audiocard_tb_arch;
