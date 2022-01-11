# NIOS-II-keypad-VHDL-timer
Controlling a DE0 board using a custom VHDL Timer in NIOS II  
**Date** 2020  
**Author** Diego P  
  

## Description
The main goal of the project is to control a DE0 programming board with an external 4x4 keyboard. 
The system is designed to have a NIOS II economy procesor and an internal timer (watchdog) described in VHDL. As IO devices, it counts with an external 4x4 keypad, 9 leds in the board, 2 7-segments indicators and 9 switches to control the leds.
Whenever one key on the keypad is pressed, the number or symbol must be shown in one of the 7-segment indicator. The keypad has a debouncing controller designed in software. 3 switches starts and stops the timer, indicated by 3 leds. The other 6 leds must be blinking when no switch is activated or key is pressed. All the IO is managed by interrupt routines.

## Watchdog Description
The watchdog is managed by two Moore machines A and B. The main purpouses of these machines is to control when a especific count for the timer is set, when is the timer started or reseted by the switches in the hardware.
  

## Top VHDL Description
Top.vhd manages the IO devices connected to the system, internally as the switches or leds indicators, and externally as the 4x4 keypad. Also manages the connection of the NIOS II procesor with the watchdog designed.
  

## ASM NIOS Program
TimerSystem.s manages the interruption routines in the system that will be called when the external IO device (keypad) is activated. Also manages the algorithm that reads which key is pressed and clears the "bouncing" effect that makes the external hardware. 
Also, manages the blinking (with the timer) of the leds when no key is pressed and the drawings of the symbols when one is.
