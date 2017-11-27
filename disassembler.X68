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
    
    lea     entend,a1
    move.b  #14,d0
    trap    #15
    
    lea     $0010,a0
    lea     $2010,a1
    move.b  #2,d0
    trap    #15
    clr     d0
    jsr     convert_to_hex
    
    
*-----------------------------------------------------------
*				     Effective Addressing					
*-----------------------------------------------------------
	move.w	test,d0
	
	jsr     get_op_code
	jsr     move_byte
	
	lsl.w   #4,d0
	lsr.w   #4,d0

	
	jsr     compute_address
	bra     done
	
	
convert_to_hex
    move.b  (a1)+,d1
    beq     return_helper
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
    move.b  #1,d5
    bra     convert_to_hex

convert_lowercase_letter_to_hex
    subi.b  #87,d1
    move.b  d1,(a0)+
    bra     convert_to_hex

convert_uppercase_letter_to_hex
    subi.b  #55,d1
    move.b  d1,(a0)+
    bra     convert_to_hex

return_helper
    rts
    
invalid
    stop    #exit

done
    stop    #exit
	
	
compute_address
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
    move.b  #',',(a2)+
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
    move.b  #'D',(a2)+
    move.b  #'A',(a2)+
    move.b  #'T',(a2)+
    move.b  #'A',(a2)+
    move.b  #' ',(a2)+
    rts
    
no_op
    move.b  #'N',(a2)+
    move.b  #'O',(a2)+
    move.b  #'P',(a2)+
    move.b  #' ',(a2)+
    rts
    
move_byte
    move.b  #'M',(a2)+
    move.b  #'O',(a2)+
    move.b  #'V',(a2)+
    move.b  #'E',(a2)+
    move.b  #'.',(a2)+
    move.b  #'B',(a2)+
    move.b  #' ',(a2)+ 
    rts 
 
move_word
    move.b  #'M',(a2)+
    move.b  #'O',(a2)+
    move.b  #'V',(a2)+
    move.b  #'E',(a2)+
    move.b  #'.',(a2)+
    move.b  #'W',(a2)+
    move.b  #' ',(a2)+ 
    rts
 
move_long
    move.b  #'M',(a2)+
    move.b  #'O',(a2)+
    move.b  #'V',(a2)+
    move.b  #'E',(a2)+
    move.b  #'.',(a2)+
    move.b  #'L',(a2)+
    move.b  #' ',(a2)+ 
    rts


*-----------------------------------------------------------
*                     Addressing Modes				 				
*-----------------------------------------------------------
data_register
    move.b  #'D',(a2)+
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    rts
    
address_register
    move.b  #'A',(a2)+
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    rts
    
address_mode_indirect
    move.b  #'(',(a2)+
    move.b  #'A',(a2)+ 
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    move.b  #')',(a2)+ 
    rts
    
address_post_increment
    move.b  #'(',(a2)+
    move.b  #'A',(a2)+ 
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    move.b  #')',(a2)+
    move.b  #'+',(a2)+
    rts
    
address_post_decrement
    move.b  #'-',(a2)+ 
    move.b  #'(',(a2)+
    move.b  #'A',(a2)+
    lea     hex_jump_table,a5
    mulu    #8,d3
    jsr     (a5,d3)
    move.b  #')',(a2)+ 
    rts
    
immediate_data
    move.b  #'#',(a2)+
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
    move.b  #'0',(a2)+ 
    rts
    
one
    move.b  #'1',(a2)+
    rts
    
two
    move.b  #'2',(a2)+
    rts

three
    move.b  #'3',(a2)+
    rts

four
    move.b  #'4',(a2)+
    rts
    
five
    move.b  #'5',(a2)+
    rts
   
six
    move.b  #'6',(a2)+
    rts
    
seven
    move.b  #'7',(a2)+
    rts

eight
    move.b  #'8',(a2)+
    rts
  
nine
    move.b  #'9',(a2)+
    rts

a
    move.b  #'A',(a2)+
    rts
  
b
    move.b  #'B',(a2)+
    rts
    
c
    move.b  #'C',(a2)+
    rts
d
    move.b  #'D',(a2)+
    rts
e
    move.b  #'E',(a2)+
    rts
f
    move.b  #'F',(a2)+
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