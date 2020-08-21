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
		RESETn: in std_logic
	);
	end component;
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
		LED => LED,
		RESETn => RESETn
	);

end audiocard_arch;
