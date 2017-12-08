*-----------------------------------------------------------
* Title      : Disassembler
* Written by : JJ Abides, Dan Florsecu, Monroe Shindelar
* Date       : November 9th 2017 
* Description: 
*-----------------------------------------------------------
cr      equ     $0d
lf      equ     $0a
exit    equ     $2700    

start   org     $1000

*-----------------------------------------------------------
*				   Displaying Startup Message
*-----------------------------------------------------------
    lea     snp,a1
    move.b  #14,d0
    trap    #15 
    
*-----------------------------------------------------------
*				           User Input				
*-----------------------------------------------------------
    lea     $2000,a1
    move.b  #2,d0
    trap    #15
    clr     d0
    jsr     convert_to_hex
    jsr     prepare_to_load_address
    jsr     get_address
    movea.l d2,a2
    
    lea     entend,a1
    move.b  #14,d0
    trap    #15
    
    lea     $0000,a0
    lea     $2000,a1
    move.b  #2,d0
    trap    #15
    clr     d0
    jsr     convert_to_hex
    jsr     prepare_to_load_address
    jsr     get_address
    movea.l d2,a3


    move.w test,(a2)+
    move.w #$4E71,(a2)



    jsr     clear_all_data_registers
    lea     $0000,a0
    
loop
   cmp      a2,a3
   beq      done
   move.w   (a2)+,d0
   jsr 	    evaluate_operation
    
    
*-----------------------------------------------------------
*				     Integrity Checks					
*-----------------------------------------------------------



	
*-----------------------------------------------------------
*                         Conversion                  
*-----------------------------------------------------------
convert_to_hex
    move.b  (a1)+,d1
    beq     return_helper
    addi.b  #1,d5
    cmpi.b  #$30,d1
    blt     invalid
    cmpi.b  #$66,d1
    bgt     invalid
    cmpi.b  #$39,d1
    ble     convert_number_to_hex
    cmpi.b  #$61,d1
    bge     convert_lowercase_letter_to_hex
    cmpi.b  #$46,d1
    bgt     invalid
    cmpi.b  #$41,d1
    bge     convert_uppercase_letter_to_hex

convert_number_to_hex
    subi.b  #$30,d1
    move.b  d1,(a0)+
    bra     convert_to_hex

convert_lowercase_letter_to_hex
    subi.b  #87,d1
    move.b  d1,(a0)+
    bra     convert_to_hex

convert_uppercase_letter_to_hex
    subi.b  #55,d1
    move.b  d1,(a0)+
    bra     convert_to_hex

prepare_to_load_address
    clr     d0
    clr     d1
    clr     d2
    lea     $0000,a0
    rts

get_address
    move.b  (a0)+,d1
    cmp.b   #0,d5
    beq     return_helper
    asl.l   #4,d2
    add.b   d1,d2
    subi.b  #1,d5
    bra     get_address


return_helper
    rts

clear_all_data_registers
    clr     d0
    clr     d1
    clr     d2
    clr     d3
    clr     d4
    clr     d5
    clr     d6
    clr     d7
    rts
    
invalid
    stop    #exit

done
    stop    #exit
	
	
compute_address
    lsl.w   #4,d0
    lsr.w   #4,d0
    jsr     get_source
    jsr     get_destination
    rts
    
    
get_source
    lea     address_mode_jump_table,a5
    jsr     get_source_register_bits
    move.b  d1,d3
    jsr     get_source_mode_bits
    mulu    #8,d1
    jsr     (a5,d1)   
    rts

get_destination
    lea     address_mode_jump_table,a5
    move.b  #',',(a0)+
    jsr     get_destination_register_bits
    move.b  d1,d3
    jsr     get_destination_mode_bits
    mulu    #8,d1
    jsr     (a5,d1)
    rts
    
*-----------------------------------------------------------
*                        Get Op Code
*-----------------------------------------------------------
get_op_code
    move.w  d0,d1
    lsr     #8,d1
    lsr     #4,d1
    rts


evaluate_operation
    jsr     get_op_code             * May optimize code later to start with checking first 4 bits for validity
    
    cmp.w   #7,d1                   * checks if the first 4 bits is 0111 (7) which doesn't exist in our supporting list of opcodes
    beq     data
    
    cmp.w   #$4E71,d0
    beq     no_op                   * check for NOP
    
    cmp.w   #$4E75,d0
    beq     return_to_sub           * check for RTS
    
    cmp.b   #01,d1                  * check for MOVE.B
    beq     check_move_type
    
    cmp.b   #3,d1                   * check for MOVE.W
    beq     check_move_type
    
    cmp.b   #2,d1
    beq     move_long               * check for MOVE.L
    
    
    * MOVEM will go here
                                    
                                    
    cmp.b   #%1101,d1                  * Check for ADD
    beq     check_add_type
    
    bra     loop                    * when are we supposed to be looping?...

check_move_type
    move.b  d1,d3                   * store size of move
    jsr     get_destination_mode_bits
    cmp     #1,d1                   * if destination bits is 001, go to moveA. Otherwise, go to move.
    beq     moveA
    bra     move                    * are we jumping back here or no?
    
check_add_type
    jsr     get_source_mode_bits
    lsr.w   #1,d1
    cmp.b   #0,d1                       *If the first 2 source mode bits (big endian) is 00, then it's ADDX, which is not supported
    beq     data
    
    jsr     get_destination_mode_bits
    cmp.b   #%0011,d1                   *If the opcode bits (destination mode bits) are 011 or 111, then it's ADDA
    beq     adda
    
    cmp.b   #%0111,d1
    beq     adda
    
    bra     add                         *Otherwise it's just ADD
    
    
*-----------------------------------------------------------
*				    Get Destination Register					
*-----------------------------------------------------------	
get_destination_register_bits
    move.w  d0,d1
    lsr.w   #8,d1
    lsr.b   #1,d1
    rts

*-----------------------------------------------------------
*				     Get Destination Mode				
*-----------------------------------------------------------    
get_destination_mode_bits
    move.w  d0,d1
    lsl.w   #7,d1
    lsr.w   #8,d1
    lsr.w   #5,d1
    rts

*-----------------------------------------------------------
*				       Get Source Mode				
*-----------------------------------------------------------
get_source_mode_bits
    move.w  d0,d1
    lsl.w   #6,d1
    lsl.w   #4,d1
    lsr.w   #8,d1
    lsr.w   #5,d1
    rts
    
*-----------------------------------------------------------
*                    Get Source Register				 				
*-----------------------------------------------------------    
get_source_register_bits
    move.w  d0,d1
    lsl.w   #8,d1
    lsl.w   #5,d1
    lsr.w   #8,d1
    lsr.b   #5,d1
    rts

*-----------------------------------------------------------
*                   Address Mode Jump Table				 			       
*-----------------------------------------------------------
address_mode_jump_table
    jsr     data_register
    rts
    jsr     address_register
    rts
    jsr     address_mode_indirect 
    rts
    jsr     address_post_increment
    rts 
    jsr     address_post_decrement
    rts
    jsr     garbage
    rts
    jsr     garbage1
    rts
    jsr     immediate_data
    rts
    
*-----------------------------------------------------------
*                        Hex Jump Table			 				
*-----------------------------------------------------------
hex_jump_table
    jsr     zero
    rts
    jsr     one
    rts
    jsr     two
    rts     
    jsr     three
    rts
    jsr     four
    rts
    jsr     five
    rts
    jsr     six
    rts 
    jsr     seven
    rts
    jsr     eight
    rts
    jsr     nine
    rts
    jsr     a
    rts
    jsr     b
    rts
    jsr     c
    rts
    jsr     d
    rts     
    jsr     e
    rts
    jsr     f
    
    
*-----------------------------------------------------------
*                        OP Codes 			 				
*-----------------------------------------------------------
data
    move.b  #'D',(a0)+
    move.b  #'A',(a0)+
    move.b  #'T',(a0)+
    move.b  #'A',(a0)+
    move.b  #' ',(a0)+
    rts
    
no_op
    move.b  #'N',(a0)+
    move.b  #'O',(a0)+
    move.b  #'P',(a0)+
    rts
    
move
    move.b  #'M',(a0)+
    move.b  #'O',(a0)+
    move.b  #'V',(a0)+
    move.b  #'E',(a0)+
    cmp.b   #%0001,d3
    beq     size_b
    
    cmp.b   #%0011,d3
    beq     size_w
    
    cmp.b   #%0010,d3
    beq     size_l

     
moveA
    cmp.b   #%0001,d3
    beq     invalid             *MOVEA cannot have byte addressing
    move.b  #'M',(a0)+
    move.b  #'O',(a0)+
    move.b  #'V',(a0)+
    move.b  #'E',(a0)+
    move.b  #'A',(a0)+
    
    cmp.b   #%0011,d3
    beq     size_w
    
    cmp.b   #%0010,d3
    beq     size_l
    
add
    move.b  #'A',(a0)+
    move.b  #'D',(a0)+
    move.b  #'D',(a0)+
    move.b  #' ',(a0)+
    
    cmp.b   #%0000,d1
    beq     size_b
    
    cmp.b   #%0100,d1
    beq     size_b
    
    cmp.b   #%0001,d1
    beq     size_w
    
    cmp.b   #%0101,d1
    beq     size_w
    
    cmp.b   #%0010,d1
    beq     size_l
    
    cmp.b   #%0110,d1
    beq     size_l
    
adda
    move.b  #'A',(a0)+
    move.b  #'D',(a0)+
    move.b  #'D',(a0)+
    move.b  #'A',(a0)+
    move.b  #' ',(a0)+
    
    cmp.b   #%0011,d1
    beq     size_w
    
    cmp.b   #%0111,d1
    beq     size_l

size_b
    move.b  #'.',(a0)+
    move.b  #'B',(a0)+
    move.b  #' ',(a0)+
    jsr     compute_address
    rts
    
size_w
    move.b  #'.',(a0)+
    move.b  #'W',(a0)+
    move.b  #' ',(a0)+
    jsr     compute_address
    rts

size_l
    move.b  #'.',(a0)+
    move.b  #'L',(a0)+
    move.b  #' ',(a0)+
    jsr     compute_address
    rts

return_to_sub
    move.b  #'R',(a0)+
    move.b  #'T',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+

*-----------------------------------------------------------
*                     Addressing Modes				 				
*-----------------------------------------------------------
data_register
    move.b  #'D',(a0)+
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    rts
    
address_register
    move.b  #'A',(a0)+
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    rts
    
address_mode_indirect
    move.b  #'(',(a0)+
    move.b  #'A',(a0)+ 
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    move.b  #')',(a0)+ 
    rts
    
address_post_increment
    move.b  #'(',(a0)+
    move.b  #'A',(a0)+ 
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    move.b  #')',(a0)+
    move.b  #'+',(a0)+
    rts
    
address_post_decrement
    move.b  #'-',(a0)+ 
    move.b  #'(',(a0)+
    move.b  #'A',(a0)+
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    move.b  #')',(a0)+ 
    rts
    
immediate_data
    move.b  #'#',(a0)+
    * Get the immediate data
    rts
    
garbage1
    rts
    
garbage
    rts

*-----------------------------------------------------------
*                        Hex Values			 				
*-----------------------------------------------------------
zero
    move.b  #'0',(a0)+ 
    rts
    
one
    move.b  #'1',(a0)+
    rts
    
two
    move.b  #'2',(a0)+
    rts

three
    move.b  #'3',(a0)+
    rts

four
    move.b  #'4',(a0)+
    rts
    
five
    move.b  #'5',(a0)+
    rts
   
six
    move.b  #'6',(a0)+
    rts
    
seven
    move.b  #'7',(a0)+
    rts

eight
    move.b  #'8',(a0)+
    rts
  
nine
    move.b  #'9',(a0)+
    rts

a
    move.b  #'A',(a0)+
    rts
  
b
    move.b  #'B',(a0)+
    rts
    
c
    move.b  #'C',(a0)+
    rts
d
    move.b  #'D',(a0)+
    rts
e
    move.b  #'E',(a0)+
    rts
f
    move.b  #'F',(a0)+
    rts
   
test	dc.w	$1003	
snp     dc.b    '                _ _                    _                                   ',cr,lf
        dc.b    '               | | |                  | |                                  ',cr,lf
        dc.b    '      ___  __ _| | |_   __ _ _ __   __| | _ __   ___ _ __  _ __   ___ _ __ ',cr,lf
        dc.b    '     / __|/ _` | | __| / _` | `_ \ / _` || `_ \ / _ \ `_ \| `_ \ / _ \ `__|',cr,lf
        dc.b    '     \__ \ (_| | | |_ | (_| | | | | (_| || |_) |  __/ |_) | |_) |  __/ |   ',cr,lf
        dc.b    '     |___/\__,_|_|\__| \__,_|_| |_|\__,_|| .__/ \___| .__/| .__/ \___|_|   ',cr,lf
        dc.b    '                                         | |        | |   | |              ',cr,lf
        dc.b    '                                         |_|        |_|   |_|              ',cr,lf
        dc.b    'Welcome to the Salt and Pepper disassembler.'                               ,cr,lf
        dc.b    'Please enter a starting address: '                                          ,0
entend  dc.b    'Please enter an ending address: '                                           ,0 

    end    start






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
