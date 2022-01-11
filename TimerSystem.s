/*___________________DESCRIPTION______________________*/
#Main program turns 8 leds on and off after 0.5 seconds
#When a key from an external keyboard is pressed, the Interrupt Handler is called.
#The interrupt routine writes the key's value into two 7-segment displays alternatively. 
#We haven't encapsulated the timer calls in a subroutine to keep the ISR independent from the main program


/*______ADRESSES___________________________________*/
.equ	addr_leds,          0x00003000
.equ	addr_cols,          0x00003010
.equ	addr_rows,          0x00003020
.equ	addr_timerout,      0x00003030
.equ 	addr_loadstart,     0x00003040
.equ	addr_cttimer,       0x00003050
.equ	addr_7segsA,        0x00003060
.equ	addr_7segsB,        0x00003070
.equ	addr_sp,            0x00001000

/*______VALUES_____________________________________*/
.equ	irq_keyboard,   0x02
.equ	time_1s,        0x5F5E100 
.equ	time_500ms,     0x17D7840
.equ	time_5ms,       0x3D090

br _start


.org 0x20
/*__IHR_______________________________________________________________________________*/
    rdctl	et, ipending            /*Copy ipending to exception temporary*/
    beq		et, zero, NO_INTERRUPT  /*If not ipending, int is not expected by device*/
    subi	ea, ea, 4               /*Positioning ea (except return addr)*/
    subi	sp, sp, 4               /*Positioning sp (stack pointer)*/
    stw		r23, 0(sp)              /*Store r23s value into SP direction in Memory*/
    andi	r23, et, irq_keyboard   /*Checks if is different to irq1*/
    beq		r23, zero, END_HANDLER  /*if true, exit IHR. Possible another method */
    call 	IRQ1

END_HANDLER:
    ldw		r23, 0(sp)              /*Restore Stack*/
    addi	sp, sp, 4               /*Stack again at last position*/
    br		EXIT_IHR	


NO_INTERRUPT:
                                    /*No peripheral interrupt*/
EXIT_IHR:
    eret
    
    
/*__IRQ1__________________________________________________________________________*/

/*__IRQ1: SAVE STACK______________________________________________*/	
IRQ1:
    subi	sp, sp, 4
    stw		r2, 0(sp)
    subi	sp, sp, 4
    stw		r3, 0(sp)
    subi	sp, sp, 4
    stw		r4, 0(sp)
    subi	sp, sp, 4
    stw		r5, 0(sp)
    subi	sp, sp, 4
    stw		r6, 0(sp)
    subi	sp, sp, 4
    stw		r7, 0(sp)
    subi	sp, sp, 4
    stw		r8, 0(sp)


/*__ISR MAIN_________________________________________*/

/*__GENERAL INIT_______________________________*/
    movia	r2, addr_cols
    movui	r3, 0x0F
    beq		r2, r3, EXIT_ISR    /*Security Check*/
    
/*__IDENTIFYING KEY_____________________*/	
    movui	r6, 0x4             /*r6 contains number of iterations.*/
    movia	r4, RowsMask        /*Has dinamic pointer.*/
POLLING:
    ldbu	r5, 0(r4)           /*Loads into r5 the current value of rowmask*/
    
    movia	r2, addr_rows
    stbio	r5, 0(r2)           /*Writes current rowmask value into device*/

    
/*__TIMER DEBOUNCING____________________________*/
    movia	r2, time_5ms		
    movia 	r3, addr_cttimer
    stwio	r2, 0(r3)			/*5ms waiting time*/
    
    movui	r2, 0x01
    movia	r3, addr_loadstart
    stbio	r2, 0(r3)			/*Load value to count*/
    movui	r2, 0x02
    stbio	r2, 0(r3)			/*Starts counting*/
    
    movia	r2, addr_timerout
    movui	r3, 0x01			/*Watches timerout*/
DEBOUNCE:
    ldbuio	r7, 0(r2)
    bne		r7, r3, DEBOUNCE
    
    movia	r2, addr_loadstart
    stbio	zero, 0(r2)			/*Clears start and load*/
    
    
/*__IDENTIFYING KEY (CONT)_______________*/	
    movia 	r2, addr_cols
    ldwio	r3, 0(r2)               /*Read cols, again, stores in r3. RO*/
    
    movui	r2, 0x000F
    bne		r3, r2, KEY_DETECTED    /*For this iteration, if cols are 0xF, then go to next iteration*/

    
/*From here continues if not key is detected*/
    addi	r4, r4, 1			/*Next pointer position for rowsmask*/
    subi	r6, r6, 1				
    beq		r6, zero, EXIT_ISR	/*If is the last iteration. Gets out*/
    br	POLLING					/*Next Poll*/
    

/*__SAVING KEY____________________________*/
/*At this point r5 has the rows value, r3 has the cols values */
KEY_DETECTED:
    roli	r5, r5, 4 			/*Converts a given value 0x0N to 0xN0*/
    or		r5, r5, r3			/*r5 stores the values in this order: rows + cols*/
    
    
/*__SHOW IN 7 SEG_______________________________________*/
/*__7SEG INIT___________________________________________*/
    movia	r4, MaskBits		/*Dynamic pointer for the bits mask*/
    movia	r6, HexbyteDot		/*Dynamic pointer for the hex values*/
    
LOOP_7SEG:	
    ldbu	r7, 0(r4)			/*Loads maskbit current value. RO*/
    ldbu	r8, 0(r6)			/*Loads hexbyte current value. RO */
    
    addi	r4, r4, 1
    addi	r6, r6, 1			/*Next pointer position for maskbits and hexbytedot*/
    
    bne     r5, r7, LOOP_7SEG	/*Compares key(rows+cols) with the keycheck register*/
    
/*From here, key is identified*/
    movia 	r2, addr_7segsB
    ldbuio	r3, 0(r2)
    movui	r2, 0xFF
    beq	r3, r2, RIGHTSEG	
        
LEFTSEG:
    movia	r2, addr_7segsA
    stbio	r8, 0(r2)			/*Loads hexbyte value into device*/
    movia	r2, addr_7segsB
    movui	r3, 0xFF
    stbio	r3, 0(r2)			/*Shutdown the other 7seg*/
    br 	EXIT_ISR	
        
RIGHTSEG:
    movia	r2, addr_7segsB
    stbio	r8, 0(r2)			/*Loads hexbyte value into device*/
    movia	r2, addr_7segsA
    movui	r3, 0xFF
    stbio	r3, 0(r2)			/*Shutdown the other 7seg*/

    
EXIT_ISR:

    movia 	r2, addr_cols
    movui	r3, 0x0F
    stbio	r3, 12(r2)			/*Clears edgecapture*/

/*__TIMER EXIT DELAY____________________________*/
    movia	r2, 0xC350			/*1 ms WAIT*/
    movia 	r3, addr_cttimer
    stwio	r2, 0(r3)			/*Sets value to count*/
    
    movui	r2, 0x01
    movia	r3, addr_loadstart
    stbio	r2, 0(r3)			/*Load value to count*/
    movui	r2, 0x02
    stbio	r2, 0(r3)			/*Starts counting*/
    
    movia	r2, addr_timerout
    movui	r3, 0x01			/*Watches timerout*/
EXIT_DELAY:
    ldbuio	r7, 0(r2)
    bne	r7, r3, EXIT_DELAY
    
    movia	r2, addr_loadstart
    stbio	zero, 0(r2)			/*Clears start and load*/
    
    
    movia	r2, addr_rows
    stbio	zero, 0(r2)		    /*Rows cleared to any key for next reading*/
    
    
/*___________________ISR RESTORE STACK______________________*/	
    ldw		r8, 0(sp)
    addi	sp, sp, 4
    ldw		r7, 0(sp)
    addi	sp, sp, 4
    ldw		r6, 0(sp)
    addi	sp, sp, 4
    ldw		r5, 0(sp)
    addi	sp, sp, 4
    ldw		r4, 0(sp)
    addi	sp, sp, 4
    ldw		r3, 0(sp)
    addi	sp, sp, 4
    ldw		r2, 0(sp)
    addi	sp, sp, 4
    
ret	
    
.global _start
_start:	

    
/*__SETUP_______________________________________*/
    movia	sp, addr_sp			/*Init stack pointer last position*/
    movui	r2, 0x01
    wrctl	status, r2			/*Activates interruptions PIE*/
    movui	r2, irq_keyboard
    wrctl	ienable, r2			/*Activates Keyboard Int*/
    movia	r2, addr_cols
    movui	r3, 0x0F
    stbio	r3, 8(r2)			/*Interrupt mask setup*/
    movui	r2, 0xFF
    movia	r3, addr_7segsA
    stbio	r2, 0(r3)
    movia	r3, addr_7segsB
    stbio	r2, 0(r3)			/*Turns off both 7segs*/
    movia	r2, addr_rows
    stbio	zero, 0(r2)			/*Rows at 0, means waiting for any key*/	
    movia	r2, addr_leds
    stbio	zero, 0(r2)			/*Turns off the leds*/
        
/*___________________MAIN______________________*/


/*__BLINK DELAY____________________________*/
BLINK_LOOP:
    movia	r3, time_500ms			
    movia 	r4, addr_cttimer
    stwio	r3, 0(r4)			/*500ms waiting time*/
    
    movui	r3, 0x01
    movia	r4, addr_loadstart
    stbio	r3, 0(r4)			/*Load value to count*/
    movui	r3, 0x02
    stbio	r3, 0(r4)			/*Starts counting*/
    stbio	zero, 0(r4)			/*clear start*/
    
    movia	r3, addr_timerout
    movui	r4, 0x01			/*Watches timerout r3.*/
    
WAIT:
    ldbuio	r7, 0(r3)
    bne		r7, r4, WAIT		/*Checks timerout r7.*/
    
    xori	r5, r5, 0xFF
    stbio	r5, 0(r2)			/*Toggle Leds on-off*/
    
    br BLINK_LOOP

    
/*__________________SOURCES_________________________*/	
.data

/*The mask is applied to the rows (output) for identifying the pressed key*/
RowsMask:
    .byte 0x0E, 0x0D, 0x0B, 0x07
    

/* Mask bits from 0 to D and symbols asterisk and hashtag. Maybe wrong order*/
MaskBits:
    .byte 	0x7D,0xEE,0xED,0xEB,0xDE,0xDD,0xDB,0xBE,0xBD,0xBB,0xE7, 0xD7, 0xB7, 0X77, 0x7E, 0x7B
    /*      0    1    2    3    4    5    6    7    8    9    A     B     C     D     asterisk hastag  */
    
/* Hex bytes for direct display on 7seg*/	
HexbyteDot:
    .byte	0xC0,0xF9,0xA4,0xB0,0x99,0x92,0x82,0xF8,0x80,0x90, 0x88, 0x83, 0xC6, 0xA1, 0xB9, 0x81

