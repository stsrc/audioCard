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
		RESETn: in std_logic;

		UART_TXD : out std_logic;
		UART_RXD : in std_logic
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


	component UART is
		Generic (
			CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
		        BAUD_RATE     : integer := 115200; -- baud rate value
		        PARITY_BIT    : string  := "none"; -- type of parity: "none", "even", "odd", "mark", "space"
		        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
	    );
	    Port (
			-- CLOCK AND RESET
			CLK         : in  std_logic; -- system clock
		        RST         : in  std_logic; -- high active synchronous reset
			-- UART INTERFACE
		        UART_TXD    : out std_logic; -- serial transmit data
		        UART_RXD    : in  std_logic; -- serial receive data
		        -- USER DATA INPUT INTERFACE
		        DIN         : in  std_logic_vector(7 downto 0); -- input data to be transmitted over UART
		        DIN_VLD     : in  std_logic; -- when DIN_VLD = 1, input data (DIN) are valid
		        DIN_RDY     : out std_logic; -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
        -- USER DATA OUTPUT INTERFACE
		        DOUT        : out std_logic_vector(7 downto 0); -- output data received via UART
		        DOUT_VLD    : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
		        FRAME_ERROR : out std_logic  -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
	    );
	end component;


	component fifo is
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
	end component;

signal FIFO_STRB_IN, FIFO_STRB_OUT : std_logic;
signal FIFO_DATA_IN, FIFO_DATA_OUT : std_logic_vector(7 downto 0);

signal REG_ADDR, ULPI_PID_IN: std_logic_vector(5 downto 0);
signal REG_VALUE_READ, REG_VALUE_WRITE, LED_REG, RXCMD, ULPI_DATA_OUT, RXCMD_REG: std_logic_vector(7 downto 0);
signal counter, counter_but_waited, counter_but_waited_but, counter_uart, ULPI_DATA_IN: std_logic_vector(7 downto 0);
signal REG_RW, REG_STRB, REG_DONE_STRB, RXCMD_STRB, ULPI_DATA_OUT_STRB, REG_FAIL_STRB: std_logic;
signal divider : std_logic_vector(19 downto 0);
signal dividerr : std_logic_vector(21 downto 0);
signal ULPI_DATA_IN_STRB, ULPI_DATA_IN_STRB_STRB, ULPI_DATA_IN_END: std_logic;

signal RST, UART_DIN_VLD, UART_DIN_RDY : std_logic;
signal UART_DIN : std_logic_vector(7 downto 0);

type state_type is (IDLE, REG_READ, REG_READ_WAIT, REG_WRITE_FUNCTION_CONTROL, REG_WRITE_WAIT_FUNCTION_CONTROL, REG_WRITE_OTG_CONTROL, REG_WRITE_WAIT_OTG_CONTROL, E);
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

	UART_0 : UART
	generic map (
		CLK_FREQ => 60e6,
		BAUD_RATE => 115200,
		PARITY_BIT => "none",
		USE_DEBOUNCER => True
	)
	port map (
		CLK => USB_CLK,
		RST => RST,
		UART_TXD => UART_TXD,
		UART_RXD => UART_RXD,
		DIN => UART_DIN,
		DIN_VLD => UART_DIN_VLD,
		DIN_RDY => UART_DIN_RDY,
		DOUT => open,
		DOUT_VLD => open,
		FRAME_ERROR => open
	);

	FIFO_0 : FIFO
	generic map (
		DATA_WIDTH => 8,
		DATA_HEIGHT => 10
	)
	port map (
		clk_in => USB_CLK,
		clk_in_resetn => RESETn,
		clk_out => USB_CLK,
		clk_out_resetn => RESETn,
		data_in => FIFO_DATA_IN,
		data_out => FIFO_DATA_OUT,
		strb_in => FIFO_STRB_IN,
		strb_out => FIFO_STRB_OUT,
		drop_in => '0',
		is_full_clk_in => open
	);

	process (USB_CLK, RESETn) begin
		if (RESETn = '0') then
			FIFO_STRB_IN <= '0';
			FIFO_DATA_IN <= (others => '0');
			RST <= '1';
			counter <= (others => '0');
		elsif (rising_edge(USB_CLK)) then
			RST <= '0';

			if (ULPI_DATA_OUT_STRB = '1') then
				FIFO_STRB_IN <= '1';
				FIFO_DATA_IN <= ULPI_DATA_OUT;
				counter <= std_logic_vector(unsigned(counter) + 1);
			else
				FIFO_STRB_IN <= '0';
				FIFO_DATA_IN <= (others => '0');
			end if;

		end if;
	end process;

	process (USB_CLK, RESETn) begin
		if (RESETn = '0') then
			counter_but_waited <= (others => '0');
			counter_but_waited_but <= (others => '0');
		elsif (rising_edge(USB_CLK)) then
			counter_but_waited <= counter;
			counter_but_waited_but <= counter_but_waited;
		end if;
	end process;

	process (USB_CLK, RESETn) begin
		if (RESETn = '0') then
			counter_uart <= (others => '0');

			UART_DIN_VLD <= '0';
			UART_DIN <= (others => '0');
			FIFO_STRB_OUT <= '0';

		elsif (rising_edge(USB_CLK)) then

			UART_DIN_VLD <= '0';
			UART_DIN <= (others => '0');
			FIFO_STRB_OUT <= '0';

			if (counter_but_waited_but /= counter_uart) then
				if (UART_DIN_RDY = '1' and UART_DIN_VLD = '0') then
					UART_DIN_VLD <= '1';
					UART_DIN <= FIFO_DATA_OUT;
					FIFO_STRB_OUT <= '1';
					counter_uart <= std_logic_vector(unsigned(counter_uart) + 1);
				end if;
			end if;
		end if;
	end process;


	process(USB_CLK, RESETn) begin
	if (RESETn = '0') then
		state <= IDLE;
		LED_REG <= (others => '1');
		divider <= (others => '0');
		dividerr <= (others => '0');
	elsif (falling_edge(USB_CLK)) then
		REG_STRB <= '0';

		if (REG_FAIL_STRB = '1') then
			state <= IDLE;
		else
			if (RXCMD_STRB = '1') then
				LED_REG <= not RXCMD;
			end if;

			case state is
			when IDLE =>
				if (dividerr /= "1111111111111111111111") then
					dividerr <= std_logic_vector(unsigned(dividerr) + 1);
				end if;
				if (dividerr = "1111111111111111111111") then
					state <= REG_WRITE_FUNCTION_CONTROL;
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
					state <= IDLE;
--					LED_REG <= REG_VALUE_READ;
				end if;
			when REG_WRITE_FUNCTION_CONTROL =>
				REG_ADDR <= "000100";
				REG_RW <= '1';
				REG_STRB <= '1';
				REG_VALUE_WRITE <= "01000101";
				state <= REG_WRITE_WAIT_FUNCTION_CONTROL;
			when REG_WRITE_WAIT_FUNCTION_CONTROL =>
				REG_STRB <= '1';
				if (REG_DONE_STRB = '1') then
					REG_STRB <= '0';
					state <= REG_WRITE_OTG_CONTROL;
				end if;
			when REG_WRITE_OTG_CONTROL =>
				REG_ADDR <= "001010";
				REG_RW <= '1';
				REG_STRB <= '1';
				REG_VALUE_WRITE <= "00000000";
				state <= REG_WRITE_WAIT_OTG_CONTROL;
			when REG_WRITE_WAIT_OTG_CONTROL =>
				REG_STRB <= '1';
				if (REG_DONE_STRB = '1') then
					REG_STRB <= '0';
					state <= E;
				end if;
			when E =>
				state <= E;
			when others =>
				state <= IDLE;
			end case;
		end if;
	end if;
	end process;

	LED <= LED_REG;

end audiocard_arch;
