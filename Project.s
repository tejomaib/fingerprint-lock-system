        AREA Project, CODE, READONLY
        EXPORT __main

__main  PROC
    ;enable gpioc clock using the appropriate address 
    ;load the gpioc clock address into r0, load the contents into r1, add 4, and store back into r0
    LDR     R0, =0x40023830 
    LDR     R1, [R0]
    ORR     R1, R1, #4     
    STR     R1, [R0]

    ;configure pins inputs (PC0, PC1, PC2) and outputs (PC4, PC5, PC6, PC7) 
    ;load base address into r0, start at effective address 0x00, clear the needed pin bits
    ;configure the needed pins appropriately so PC0, PC1, PC2 configured to be 00 for input
    ;PC4, PC5, PC6, PC7 configured to be 01 for output and store all these values back into r0
    LDR     R0, =0x40020800       
    LDR     R1, [R0, #0x00]       
    BIC     R1, R1, #0x0000003F    
    BIC     R1, R1, #0x0000FF00    
    ORR     R1, R1, #0x00000100       
   ORR     R1, R1, #0x00000400     
    ORR     R1, R1, #0x00001000      
    ORR     R1, R1, #0x00004000    
    STR     R1, [R0, #0x00]

    ; pull-down register
    ;start at the next available memory which is 0x0C and clear pins 0-5
    ;clear the first 5 bits and configure PC0, PC1, PC2 to be 10 for pull-down resistors
    ;following configurations, store the final value back into r0 at the effective address
    LDR     R1, [R0, #0x0C]       
    BIC     R1, R1, #0x0000003F
   ORR     R1, R1, #0x00000002
   ORR     R1, R1, #0x00000008
   ORR     R1, R1, #0x00000020       
    STR     R1, [R0, #0x0C]

;initiate the loop and make it check for the pins that are enabled as inputs from IDR
loop
    LDR     R3, [R0, #0x10]       

    ;if pc0 high then pc4 and pc7 are high go to pc0 function
    ;condition works by checking if pc0 is equal to 1
    AND     R4, R3, #1
    CMP     R4, #1
    BEQ     pc0_check

    ;if pc1 high pc5 high go to pc1 function  
    ;condition works by checking if pc1 is equal to 1
    AND     R4, R3, #2
    CMP     R4, #2
    BEQ     pc1_check

    ;if pc2 is high then pc6 set and if pc2 low then pc6 cleared
    ;condition works by checking if pc2 is equal to 1
    ;this condition is the only one that doesn’t go into a function because it simply checks if the  
    ;program is executing and mirrors the response of the program
    AND     R4, R3, #4 
    LDR     R6, [R0, #0x14]
    BIC     R6, R6, #0x00000040       
    CMP     R4, #4
    ORREQ   R6, R6, #0x00000040       
    STR     R6, [R0, #0x14]

    ;end of the loop
    B       loop

;this function turns pc4 and pc7 on, the delay is called, and then pc4 and pc7 are turned off
pc0_check
    ; pc4/pc7 on
    LDR     R6, [R0, #0x14]      
    ORR     R6, R6, #0x00000010       
    ORR     R6, R6, #0x00000080       
    STR     R6, [R0, #0x14]
    BL      delay
    ; pc4/pc7 off
    LDR     R6, [R0, #0x14]
    BIC     R6, R6, #0x00000010       
    BIC     R6, R6, #0x00000080       
    STR     R6, [R0, #0x14]
pc0_execute
    LDR     R3, [R0, #0x10]
    AND     R4, R3, #1
    CMP     R4, #1
    BEQ     pc0_execute
    B       loop

;this function turns pc5 on, a delay is called, and then pc5 is turned off
pc1_check
    ; pc5 on
    LDR     R6, [R0, #0x14]
    ORR     R6, R6, #0x00000020
    STR     R6, [R0, #0x14]
    BL      delay
    ;pc5 off
    LDR     R6, [R0, #0x14]
    BIC     R6, R6, #0x00000020
    STR     R6, [R0, #0x14]
pc1_execute
    LDR     R3, [R0, #0x10]
    AND     R4, R3, #2
    CMP     R4, #2
    BEQ     pc1_execute
    B       loop

;delay routine for 3 seconds
;with the counter sent to 3 seconds in the outer loop the loops work as a countdown constantly 
;checking if the counter reached 0 in order to break the delay and return to the respective 
;functions
delay   PROC
    MOV     R12, #0x120000
outer
    SUBS    R12, R12, #1
    MOV     R5, #1
inner
    SUBS    R5, R5, #1
    BNE     inner
    CMP     R12, #0
    BNE     outer
    BX      LR
ENDP

        LTORG
        END
;end of the program
