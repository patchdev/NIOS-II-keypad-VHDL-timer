--NIOS II/e

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY top IS 
	PORT(
		CLOCK_50	:	IN	STD_LOGIC;
		RESET		:	IN	STD_LOGIC;
		KEYB_IN		:	IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
		KEYB_OUT	:	OUT	STD_LOGIC_VECTOR(3 DOWNTO 0);
		SEGMENT_0 	: 	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		SEGMENT_1 	: 	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
		LEDS		: 	OUT	STD_LOGIC_VECTOR(6 DOWNTO 0);
		TIMER_OUT	:	OUT	STD_LOGIC;
		TIMER_LOAD	:	OUT	STD_LOGIC;
		TIMER_START	:	OUT STD_LOGIC
	);
END top;

ARCHITECTURE keyboard_system OF top IS
	
	SIGNAL	START_C_INT		:	STD_LOGIC;
	SIGNAL	LOAD_INT		:	STD_LOGIC;
	SIGNAL	CT_INT			:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL	TIMER_OUT_INT	:	STD_LOGIC;
	SIGNAL	AUX_RESET		:	STD_LOGIC := '1';
	
	

	COMPONENT Nios is
        PORT (
            clk_clk                 :	IN  STD_LOGIC                     := 'X';             -- clk
            reset_reset_n           :	IN  STD_LOGIC                     := 'X';             -- reset_n
            keyboard_cols_export    :	IN  STD_LOGIC_VECTOR(3 DOWNTO 0)  := (others => 'X'); -- export
            keyboard_rows_export    :	OUT STD_LOGIC_VECTOR(3 DOWNTO 0);                     -- export
            id7segments_1_export    :	OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                     -- export
            id7segments_0_export    :	OUT STD_LOGIC_VECTOR(7 DOWNTO 0);                     -- export
            leds_export             :	OUT STD_LOGIC_VECTOR(6 DOWNTO 0);                     -- export
            timer_out_export        :	IN  STD_LOGIC                     := 'X';             -- export
            timer_load_start_export :	OUT STD_LOGIC_VECTOR(1 DOWNTO 0)  :=(others => '0');  -- export
            timer_ct_export         :	OUT STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0')  -- export
        );
    	END COMPONENT Nios;
	
	COMPONENT watchdog IS
		PORT(
			CLK			:	IN	STD_LOGIC;
			RESET		:	IN	STD_LOGIC;
			START_C		:	IN	STD_LOGIC;
			LOAD		:	IN	STD_LOGIC;
			CTC			:	IN	STD_LOGIC_VECTOR(31 DOWNTO 0);
			TIMER_OUT 	:	OUT STD_LOGIC
		);
	END COMPONENT watchdog;	
	
		
		
	BEGIN
	
	    mySystem : Nios
		PORT MAP (
		    clk_clk                 	=> CLOCK_50,        -- clk.clk
		    reset_reset_n           	=> RESET,           -- reset.reset_n
		    keyboard_cols_export    	=> KEYB_IN,    		-- keyboard_cols.export
		    keyboard_rows_export    	=> KEYB_OUT,    	-- keyboard_rows.export
		    id7segments_1_export    	=> SEGMENT_1,    	-- id7segments_1.export
		    id7segments_0_export    	=> SEGMENT_0,    	-- id7segments_0.export
		    leds_export             	=> LEDS,            -- leds.export
		    timer_out_export        	=> TIMER_OUT_INT,   -- timer_out.export
		    timer_load_start_export(0) 	=> LOAD_INT, 		-- timer_load_start.export
		    timer_load_start_export(1) 	=> START_C_INT,		-- timer_load_start.export
		    timer_ct_export         	=> CT_INT       	-- timer_ct.export
		);
	
		myTimer	: watchdog
			PORT MAP (
				CLK			=> CLOCK_50,
				RESET		=> RESET,
				START_C		=> START_C_INT, 
				LOAD		=> LOAD_INT,
				CTC			=> CT_INT,
				TIMER_OUT 	=> TIMER_OUT_INT
			);
		
		--Timer out, load and start assignments
			TIMER_OUT 	<= TIMER_OUT_INT;
			TIMER_LOAD 	<= LOAD_INT;
			TIMER_START <= START_C_INT;
		--Reset inversion
		-- AUX_RESET <= RESET;
END keyboard_system;


