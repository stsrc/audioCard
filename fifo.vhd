-- fifo was written with help of RAM example found in FADE ethernet protocol.
-- project can be found here: www.opencores.org/project,fade_ether_protocol
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-- *_in ports mean that it is for input data and control pins.
-- *_out as expected, it is to output data from fifo.
entity fifo is
	generic (
		DATA_WIDTH : integer := 64;
		DATA_HEIGHT : integer := 10
	);
	port (
		clk_in		: in std_logic;
		clk_in_resetn	: in std_logic;
		clk_out		: in std_logic;
		clk_out_resetn  : in std_logic;
		data_in		: in std_logic_vector(DATA_WIDTH - 1 downto 0);
		data_out	: out std_logic_vector(DATA_WIDTH - 1 downto 0);
		strb_in		: in std_logic;
		strb_out	: in std_logic;
		drop_in		: in std_logic;
		is_full_clk_in	: out std_logic
	);
end fifo;

architecture fifo_arch of fifo is

signal head, head_save, tail : unsigned(DATA_HEIGHT - 1 downto 0);

signal gray_tail_clkout : unsigned(DATA_HEIGHT - 1 downto 0);
signal gray_tail_clkin_meta, gray_tail_clkin_reg : unsigned(DATA_HEIGHT - 1 downto 0);
signal tail_clkin, tail_clkin_tmp : unsigned(DATA_HEIGHT - 1 downto 0);

type mem_type is array (2**DATA_HEIGHT - 1 downto 0) of std_logic_vector(DATA_WIDTH - 1 downto 0);
signal mem : mem_type;

procedure GRAY2BIN (
	signal tail_clkin 		: inout unsigned(DATA_HEIGHT - 1 downto 0);
	signal gray_tail_clkin_reg 	: in unsigned(DATA_HEIGHT - 1 downto 0))
is
begin
	tail_clkin(DATA_HEIGHT - 1) <= gray_tail_clkin_reg(DATA_HEIGHT - 1);
	for i in DATA_HEIGHT - 2 downto 0 loop
		tail_clkin(i) <= tail_clkin(i + 1) xor gray_tail_clkin_reg(i);
	end loop;
end GRAY2BIN;

begin

	process (clk_in, clk_in_resetn) begin
		if (clk_in_resetn = '0') then
			is_full_clk_in 		<= '0';
			head 			<= (others => '0');
			head_save 		<= (others => '0');
			gray_tail_clkin_meta 	<= (others => '0');
			gray_tail_clkin_reg 	<= (others => '0');
			tail_clkin	 	<= (others => '0');
		elsif (rising_edge(clk_in)) then
			is_full_clk_in <= '0';

			gray_tail_clkin_meta <= gray_tail_clkout;
			gray_tail_clkin_reg <= gray_tail_clkin_meta;
			tail_clkin <= tail_clkin_tmp;

			case (strb_in) is
			when '1' =>
				if (head = tail_clkin - 1) then
					is_full_clk_in <= '1';
					head <= head_save;
				elsif (drop_in = '1') then
					head <= head_save;
				else
					mem(to_integer(head)) <= data_in;
					head <= head + 1;
				end if;
			when '0' =>
				head_save <= head;
			when others =>
				head <= head_save;
			end case;
		end if;
	end process;

	process(gray_tail_clkin_reg, tail_clkin_tmp) begin
		GRAY2BIN(tail_clkin_tmp, gray_tail_clkin_reg);
	end process;

	process (clk_out, clk_out_resetn) begin
		if (clk_out_resetn = '0') then
			tail 			<= (others => '0');
			gray_tail_clkout 	<= (others => '0');
		elsif (rising_edge(clk_out)) then
			if (strb_out = '1') then
				data_out <= mem(to_integer(tail + 1));
				tail <= tail + 1;
			else
				data_out <= mem(to_integer(tail));
			end if;

			--BIN to GRAY conversion.
			gray_tail_clkout <= tail xor ("0" & tail(DATA_HEIGHT - 1 downto 1));
			--End of convertion.
		end if;
	end process;

end fifo_arch;
