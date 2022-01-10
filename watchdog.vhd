--Watchdog

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


ENTITY watchdog IS
  PORT (CLK, RESET, START_C, LOAD 	: IN STD_LOGIC;
        CTC 				                : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
        TIMER_OUT 			            : OUT STD_LOGIC
       );
END watchdog;


ARCHITECTURE behavioral OF watchdog IS
--No Component
--No Constants
--Types
  TYPE state_a IS (SA0, SA1, SA2, SA3, SA4);
  TYPE state_b IS (SB0, SB1, SB2, SB3);
-- Signals
  SIGNAL NEXT_SA, CURRENT_SA 		      : state_a := SA0;
  SIGNAL NEXT_SB, CURRENT_SB 		      : state_b := SB0;
  SIGNAL ICV, CHV 			              : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0'); 
  SIGNAL RESETICV, ENICV, EDGES,IMIN 	:  STD_LOGIC;
  SIGNAL counter 			                : UNSIGNED(31 DOWNTO 0) := (OTHERS => '0');

  BEGIN   
-- icv-chv comparer
comparer : PROCESS(ICV, CHV)
BEGIN
  IF (ICV < CHV) THEN IMIN<='1'; ELSE IMIN<='0';
  END IF;  
END PROCESS comparer;
      
-- Moore machine edges (MACHINE B)

-- Machine B clock/reset
edges_clk : PROCESS(RESET, CLK)
  BEGIN
  IF(RESET = '0') THEN CURRENT_SB<=SB0;
  ELSIF (RISING_EDGE(CLK)) THEN CURRENT_SB <= NEXT_SB;
  END IF;
END PROCESS edges_clk;

--Machine B states 
state_manager_b : PROCESS(CURRENT_SB, START_C, RESET)
BEGIN
  CASE CURRENT_SB IS
    WHEN SB0 => IF (START_C = '0') THEN NEXT_SB<=SB1; ELSE NEXT_SB<=SB0; END IF;
    WHEN SB1 => IF (START_C = '1') THEN NEXT_SB<=SB2; ELSE NEXT_SB<=SB1; END IF;
    WHEN SB2 => IF (START_C = '1') THEN NEXT_SB<=SB3; ELSE NEXT_SB<=SB1; END IF;
    WHEN SB3 => IF (START_C = '0') THEN NEXT_SB<=SB1; ELSE NEXT_SB<=SB3; END IF;
  END CASE;    
END PROCESS state_manager_b;

--Machine B outputs
outputs_b : PROCESS(CURRENT_SB)
BEGIN
  CASE CURRENT_SB IS
    WHEN SB2 => EDGES<='1';
    WHEN OTHERS => EDGES<='0';
  END CASE;      
END PROCESS outputs_b;



-- Moore machine main (MACHINE A)

-- Machine A clock/reset
main_clk : PROCESS(CLK, RESET)
BEGIN
  IF(RESET = '0') THEN CURRENT_SA<=SA0;
  ELSIF (RISING_EDGE(CLK)) THEN CURRENT_SA <= NEXT_SA;
  END IF;
END PROCESS main_clk;

--Machine A states
state_manager_a : PROCESS (CURRENT_SA, LOAD, EDGES, IMIN)
BEGIN
  CASE CURRENT_SA IS
    WHEN SA0 => IF (LOAD = '1') THEN NEXT_SA<=SA2; 
               ELSIF (EDGES ='1') THEN NEXT_SA<=SA3; ELSE NEXT_SA <= SA0; END IF;
               
    WHEN SA1 => IF (LOAD = '1') THEN NEXT_SA<=SA2;
               ELSIF (EDGES ='0') THEN NEXT_SA<=SA3; ELSE NEXT_SA<=SA1; END IF;
                 
    WHEN SA2 => IF (LOAD = '1') THEN NEXT_SA<=SA2;
               ELSIF (EDGES = '1') THEN NEXT_SA<=SA3; ELSE NEXT_SA<=SA0; END IF; 
                 
    WHEN SA3 => IF (LOAD = '1') THEN NEXT_SA<=SA2; ELSIF (EDGES = '1') THEN NEXT_SA<=SA1;
               ELSIF (IMIN='0') THEN NEXT_SA<=SA4; ELSE NEXT_SA<=SA3; END IF;
                 
    WHEN SA4 => IF (LOAD = '1') THEN NEXT_SA<=SA2;
               ELSIF (EDGES = '1') THEN NEXT_SA<=SA1; ELSE NEXT_SA<=SA4; END IF;            
  END CASE;  
END PROCESS state_manager_a; 

-- Machine A outputs
outputs_a : PROCESS(CURRENT_SA)
BEGIN
  CASE CURRENT_SA IS
    WHEN SA3    => RESETICV<='1'; ENICV<='1'; TIMER_OUT<='0';
    WHEN SA4    => RESETICV<='1'; TIMER_OUT<='1'; ENICV<='0'; 
    WHEN OTHERS => RESETICV<='0'; TIMER_OUT<='0'; ENICV<='0';
  END CASE;
  IF (CURRENT_SA = SA2) THEN CHV<=CTC; 
  END IF;  

END PROCESS outputs_a;


-- Counter ICV
counter_icv : PROCESS (CLK)

BEGIN
IF ((RESETICV = '0')AND RISING_EDGE(CLK)) THEN COUNTER <= (OTHERS => '0');
 END IF;
    
  IF (ENICV = '1' AND RISING_EDGE(CLK)) THEN
    counter <= counter + 1;  
    END IF;
 
END PROCESS counter_icv;

-- Counter output management
ICV <= STD_LOGIC_VECTOR(counter);

END behavioral; 

