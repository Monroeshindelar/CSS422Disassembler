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
    
    jsr     read_file
    
    lea     s_notif,a1
    move.b  #14,d0
    trap    #15    

    jsr     clear_all_data_registers
    lea     $0000,a0
    
    
    
    
loop
    lea      $0000,a0
    cmp.l    a2,a3
    beq      done
    move.w   (a2)+,d0
    jsr 	 evaluate_operation
    jsr      print
    bra      loop
    
    
*-----------------------------------------------------------
*				     Integrity Checks					
*-----------------------------------------------------------



	
*-----------------------------------------------------------
*                       Conversion                  
*-----------------------------------------------------------
convert_to_hex
    move.b  (a1)+,d1
    beq     return_helper
    cmp.b   #$FF,d1
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
    
read_file
    lea     f_name,a1
    move.b  #51,d0
    trap    #15
    
    move.l  #f_size,d2
    lea     $500,a1
    move.b  #53,d0
    trap    #15
    movea.l a1,a6
    movea.l a2,a4
    jsr     convert_file_contents
    rts
    
convert_file_contents
    clr     d3
    lea     $00a0,a0
    cmp.w   #0,d2
    beq     return_helper
    move.w  (a1)+,d0
    move.w  a1,d7
    lea     $0010,a1
    move.w  d0,(a1)
    jsr     convert_to_hex
    clr     d0
    move.b  #2,d5
    lea     $00a0,a0
    jsr     convert_helper
    movea.l d7,a1
    subi.b  #2,d2
    move.b  d3,(a4)+
    bra     convert_file_contents
    
convert_helper
    move.b  (a0)+,d0
    cmp.b   #0,d5
    beq     return_helper
    asl.l   #4,d3
    add.b   d0,d3
    subi.b  #1,d5
    bra     convert_helper
    
print
    move.b  #$00,(a0)
    lea     $0000,a1
    moveq   #13,d0
    trap    #15
    move.b  #16,d5
    lea     $0000,a0
    jsr     clear_address
    rts

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
    
clear_address
    cmp.b   #0,d5
    beq     return_helper
    move.b  #$FF,(a0)+
    subi.b  #1,d5
    bra     clear_address
    
invalid
    lea     endinv,a1
    move.b  #14,d0
    trap    #15
    bra     exit_prog

done
    lea     endprog,a1
    move.b  #14,d0
    trap    #15
    
exit_prog
    move.b  #9,d0
    trap    #15

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
    jsr     get_op_code                 * May put check for 0100 opcodes up here later
    move.b  d1,d7
    
    cmp.w   #7,d1                       * checks if the first 4 bits is 0111 (7) which doesn't exist in our supporting list of opcodes
    beq     data
    
    cmp.w   #$4E71,d0
    beq     no_op                       * check for NOP
    
    cmp.w   #$4E75,d0
    beq     return_to_sub               * check for RTS
    
    cmp.b   #01,d1                      * check for MOVE.B
    beq     check_move_type
    
    cmp.b   #3,d1                       * check for MOVE.W
    beq     check_move_type
    
    cmp.b   #2,d1
    beq     check_move_type             * check for MOVE.L
    
    
    cmp.b   #4,d1
    beq     0100_Opcodes                * Branch to code that checks through a set of opcodes with 0100 as their start (big endian)
                                    
                                    
    cmp.b   #%1101,d1                   * Check for ADD
    beq     check_add_type
    
    cmp.b   #%1001,d1                   * Check for SUB
    beq     check_sub_type
    
    cmp.b   #%0101,d1                   * Check for SUBQ: Check first 4 bits then diferentiate between other opcodes with the same 4 bits
    beq     check_subq
    
    cmp.b   #$8,d1
    beq     check8                      * Check if the opcode is DIVS or OR
    
    cmp.b   #$C,d1
    beq     check_muls                  * Check if the opcode is MULS
    
    cmp.b   #0,d1
    beq     0000_Opcodes
    
    bra     loop                        * Should we branch to data instead?

check_move_type
    move.b  d1,d3                       * store size of move
    jsr     get_source_mode_bits
    cmp     #%111,d1                    * If source mode bits are 111
    beq     check_move_source_register  
    
continue_move_check
    jsr     get_destination_mode_bits
    cmp.b   #%001,d1
    beq     moveA                       * If destination mode bits are 001, it's MOVEA
    
    cmp.b   #%111,d1
    beq     check_move_destination_register     * If destination mode is 111, check the register for validity
    
    bra     move                        *Otherwise, it's a valid MOVE

check_move_destination_register
    jsr     get_destination_register_bits
    cmp.b   #1,d1
    bgt     data                          * If register bit is greater than 1, it's DATA
    
    bra     move                          * Otherwise, it's a valid MOVE
    
check_move_source_register
    jsr     get_source_register_bits
    cmp.b   #%100,d1
    bgt     data                            *If register bits are greater than %100, its invalid
    
    bra    continue_move_check
    

check_add_type
    jsr     get_destination_mode_bits
    move.b  d1,d3                           *Storing size in d3
    
    lsl.b   #6,d3                           *Isolating size bits
    lsr.b   #6,d3
    lsr.b   #2,d1                           *Isolating direction bit in D1
    
    cmp.b   #%11,d3
    beq     check_addA_mode                 * If size bits are 11, it's ADDA
    
    cmp.b   #1,d1                           * If directional bit is 1 (EA Destination), check available addressing modes for that
    beq     add_EA_destination_type
    
    jsr     get_source_mode_bits            * Otherwise, it uses a data register as the destination (<ea> + Dn -> Dn), so check the available addressing for that
    cmp.b   #%111,d1                        * If mode is 111, check source register bits for validity
    beq     check_add_source_register
    
       
    bra     add                             *Otherwise it's just ADD
    
add_EA_destination_type
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    ble     data                            * If source mode bits are less than or equal to 1, it's invalid
    
    cmp.b   #%111,d1
    beq     check_add_source_registerEA     * Checks available register bits for mode 111 in EA Destination mode
    
    bra     add                             * Otherwise, it's a legit ADD
    
check_add_source_registerEA
    jsr     get_source_register_bits
    cmp.b   #%01,d1
    bgt     data                            * register bits cannot be greater than 1
    
    bra     add                             * otherwise it's a valid ADD
check_add_source_register
    jsr     get_source_register_bits
    cmp.b   #%100,d1
    bgt     data                            * If register bits are greater than 4, it's invalid
    
    bra     add                             * Otherwise, it's a valid ADD
    
check_addA_mode
    move.b  d1,d3                           * Move the size bit into d3
    jsr     get_source_mode_bits
    cmp.b   #%111,d1
    beq     check_addA_source_register      * If mode bits are 111, validate the register bits
    
    bra     addA                           * Else, it's a legit ADDA
check_addA_source_register
    jsr     get_source_register_bits
    cmp.b   #%100,d1                        * Register bits cannot exceed 4
    bgt     data
        
    bra     addA                            * else, it's a legit ADDA
    
    
check_sub_type
    jsr     get_destination_mode_bits
    move.b  d1,d3                           *Storing size in d3
    
    lsl.b   #6,d3                           *Isolating size bits
    lsr.b   #6,d3
    lsr.b   #2,d1                           *Isolating direction bit in D1
    
    cmp.b   #%11,d3
    beq     data                            * If size bits are 11, it's not valid
    
    cmp.b   #1,d1                           * If directional bit is 1 (EA Destination), check available addressing modes for that
    beq     sub_EA_destination_type
    
    jsr     get_source_mode_bits            * Otherwise, it uses a data register as the destination (Dn - <ea> -> Dn), so check the available addressing for that
    cmp.b   #%111,d1                        * If mode is 111, check source register bits for validity
    beq     check_sub_source_register
  
    bra     sub                             *Otherwise it's just SUB

sub_EA_destination_type
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    ble     data                            * If mode bits are less than or equal to 1, it's invalid
    
    cmp.b   #%111,d1
    beq     check_sub_source_registerEA
    
    bra     sub

check_sub_source_registerEA
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data
    
    bra     sub
check_sub_source_register
    jsr     get_source_register_bits
    cmp.b   #%100,d1
    bgt     data
    
    bra     sub
    
check_subq
    jsr     get_destination_mode_bits
    move.b  d1,d3
    lsl.b   #6,d3
    lsr.b   #6,d3                       * Storing size in d3
    cmp.b   #%11,d3                     * If size was 11, it's invalid because those bits are reserved for Scc and DBcc, which are not supported
    beq     data
    
    lsr.b   #2,d1                       * Isolating the last bit of the destination mode
    cmp.b   #0,d1                       * If bit was 0, it's ADDQ which is not supported
    beq     data
    
    jsr     get_source_mode_bits        * Now checking if the source mode bits is 111
    cmp.b   #%111,d1
    beq     check_subq_source_register  * check for valid registers
    
    bra     subq                        * Otherwise it's a legit subq
 
check_subq_source_register
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data                        * If register bits are greater than 1, it's invalid
    
    bra     subq                        * Otherwise it's a legit subq
    
    
0100_Opcodes                            * Supported 0100 opcodes: MOVEM, LEA, NEG, and JSR
    move.w  d0,d1
    ror.w   #8,d1
    cmp.b   #$44,d1                     * Checking the 4 bits after the first 4 (big endian)
    beq     check_neg                   * If it's %0100, check if it's a valid NEG
    
    rol.w   #2,d1
    cmp.b   #$3A,d1
    beq     check_jsr                   * Really weird way of checking if jsr
    
    jsr     get_destination_mode_bits
    cmp.b   #%111,d1
    beq     check_lea                   * If destination mode bits is 111, it could be LEA
    
    lsr     #1,d1
    move.b  d1,d3
    
    jsr     get_destination_register_bits
    lsl.w   #7,d1
    add.b   d1,d3
    
    lsl.w   #8,d1
    add.b   d1,d3                       * A really weird pseudo AND operation
    
    cmp.b   #%10,d3
    beq     check_moveM                 * This could be a MOVEM operation. Checking if it's valid
    
    
    bra     data                        * Otherwise, it's invalid


check_neg
    jsr     get_destination_mode_bits
    cmp.b   #%11,d1
    beq     data                        * If size bits is %11, it's invalid
    
    move.b  d1,d3                       * store the size in d3
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    beq     data                        * If mode bits is 001, it's invalid
    
    cmp.b   #%111,d1
    beq     check_neg_source_register   * If mode bits is 111, check for valid register bits
    
    bra     neg                         * Otherwise, it's a valid NEG

check_neg_source_register
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data                        * If register bits is greater than 1, it's invalid
    
    bra     neg                         * otherwise, it's a valid NEG
    

check_jsr
    jsr     get_source_mode_bits
    cmp.b   #%010,d1                    * Valid mode bits are 010, 101, 110, and 111 with specific register bits
    beq     jsr
    
    cmp.b   #%101,d1
    beq     jsr
    
    cmp.b   #%110,d1
    beq     jsr
    
    cmp.b   #%111,d1
    beq     check_jsr_source_register   * If 111, check register bits for validity
    
    bra     data                        * Otherwise, it's invalid

check_jsr_source_register
    jsr     get_source_register_bits
    cmp.b   #%011,d1
    bgt     data                        * If register bits is over 3, it's invalid
    
    bra     jsr                         * Otherwise, it's a valid JSR
    
    
check_lea
    jsr     get_source_mode_bits
    cmp.b   #%010,d1
    beq     lea
    
    cmp.b   #%101,d1
    beq     lea
    
    cmp.b   #%110,d1
    beq     lea
    
    cmp.b   #%111,d1
    beq     check_lea_source_register
    
    bra     data                        * Otherwise it's invalid               
    
check_lea_source_register
    jsr     get_source_register_bits
    cmp.b   #%011,d1
    bgt     data                        * If register bits is greater than 3, it's invalid
    
    bra     lea                         * Otherwise it's a valid LEA

    
check_movem
    jsr     get_source_mode_bits
    move.b  d1,d3
    cmp.b   #%010,d3
    beq     moveM
    
    cmp.b   #%101,d3
    beq     moveM
    
    cmp.b   #%110,d3
    beq     moveM
    
    jsr     get_destination_register_bits
    lsl.b   #6,d1
    lsr.b   #7,d1                       * Isolate the directional bit
    
    cmp.b   #%111,d3
    beq     check_moveM_reg
    
    cmp.b   #1,d1
    beq     moveM_memToReg
    
    cmp.b   #%100,d3
    beq     moveM
    
    bra     data                        * Otherwise, it's not MOVEM

check_moveM_reg                         *This section checks the direction if it's memory to register. If not, it checks for valid register to memory 111 address modes
    cmp.b   #1,d1                       *d1 holds the destination register bit
    beq     moveM_memToReg111
    
    jsr     get_source_register_bits
    cmp.b   #1,d1                       *If register bits are greater than 1, it's DATA
    bgt     data
    
    bra     moveM                       * Otherwise, it's a legit MOVEM
    
moveM_memToReg111                       * This section checks the available 111 addressing modes in memory to register mode
    jsr     get_source_register_bits
    cmp.b   #3,d1
    bgt     data                        * If register bits are greater than 3 it's DATA
    
    bra     moveM                        * Otherwise, it's a legit MOVEM

moveM_memToReg                          * This section checks addressing modes that are available in memory to register mode (excluding 111 mode)
    cmp.b   #%011,d3
    beq     moveM
    
    bra     data                        * otherwise it's not MOVEM
    
    
check_8
    jsr     get_destination_mode_bits
    cmp.b   #%111,d1
    beq     check_divs                  * Check if it's a valid DIVS
    
    cmp.b   #%011,d1
    bne     check_or
    
    bra     data                        * Otherwise, it's invalid
    rts

check_divs
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_divs_source_register
    
    bra     divs
    
check_divs_source_register
    jsr     get_source_register_bits
    cmp.b   #%100,d1
    bgt     data
    
    bra     divs
    
    
check_muls
    jsr     get_destination_mode_bits
    cmp.b   #%111,d1
    beq     check_muls_source_mode
    bne     data
    rts
    
check_muls_source_mode
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_muls_source_register
    
    bra     muls
check_muls_source_register
    jsr     get_source_register_bits
    cmp.b   #%100,d1
    bgt     data
    
    bra     muls

check_or
    move.b  d1,d3
    lsl.b   #6,d3
    lsr.b   #6,d3                           * getting size
    
    lsr.b   #2,d1                           * Isolate direction bit
    
    cmp.b   #1,d1                           * If direction bit is 1, location is destination operand, otherwise, location is source operand
    beq     check_or_destination_operand
    
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_or_source_register0
    
    bra     or
    
check_or_source_register0
    jsr     get_source_register_bits
    cmp.b   #%100,d1
    bgt     data
    
    bra     or
check_or_destination_operand
    jsr     get_source_mode_bits
    cmp.b   #%000,d1
    beq     data
    
    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_or_source_register1
    
    bra     or

check_or_source_register1
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data
    
    bra     or

0000_Opcodes
    move.w  d0,d1
    lsr.w   #6,d1
    
    cmp.b   #$22,d1
    beq     check_bclr                          * Check if valid BCLR
    
    lsr.w   #2,d1
    
    cmp.b   #0,d1
    beq     check_ori                           * Check if valid ORI
    
    cmp.b   #$C,d1
    beq     check_cmpi                          * Check if valid CMPI
    
    bra     data                                * Otherwise, it's DATA

check_ori
    jsr     get_destination_mode_bits
    cmp.b   #3,d1
    beq     data                                * cannot have %11 bits for size
    
    move.b  d1,d3                               * store size in d3
    
    jsr     get_source_mode_bits
    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_ori_source_register
    
    bra     ori

check_ori_source_register
    jsr     get_source_register_bits
    cmp.b   #1,d1
    bgt     data
    
    bra     ori
 
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
    beq     data             *MOVEA cannot have byte addressing
    move.b  #'M',(a0)+
    move.b  #'O',(a0)+
    move.b  #'V',(a0)+
    move.b  #'E',(a0)+
    move.b  #'A',(a0)+
    
    cmp.b   #%0011,d3
    beq     size_w
    
    cmp.b   #%0010,d3
    beq     size_l
    
    
moveM
    move.b  #'M',(a0)+
    move.b  #'O',(a0)+
    move.b  #'V',(a0)+
    move.b  #'E',(a0)+
    move.b  #'M',(a0)+

    jsr     get_destination_mode_bits
    lsl.b   #7,d1
    lsr.b   #7,d1
    
    cmp.b   #0,d1
    beq     size_w
    
    bra     size_l
    
add
    move.b  #'A',(a0)+
    move.b  #'D',(a0)+
    move.b  #'D',(a0)+
    
    cmp.b   #%00,d3
    beq     size_b
    
    cmp.b   #%01,d3
    beq     size_w
    
    bra     size_l
    
addA
    move.b  #'A',(a0)+
    move.b  #'D',(a0)+
    move.b  #'D',(a0)+
    move.b  #'A',(a0)+
    
    cmp.b   #0,d3
    beq     size_w
    
    bra     size_l

sub
    move.b  #'S',(a0)+
    move.b  #'U',(a0)+
    move.b  #'B',(a0)+
    
    cmp.b   #%00,d3
    beq     size_b
    
    cmp.b   #%01,d3
    beq     size_w
    
    bra     size_l
    
subq
    move.b  #'S',(a0)+
    move.b  #'U',(a0)+
    move.b  #'B',(a0)+
    move.b  #'Q',(a0)+
    
    cmp.b   #%00,d3        
    beq     size_b
    
    cmp.b   #%01,d3
    beq     size_w
    
    bra     size_l
    
lea
    move.b  #'L',(a0)+
    move.b  #'E',(a0)+
    move.b  #'A',(a0)+
    move.b  #' ',(a0)+
    jsr     compute_address
    rts
    
neg
    move.b  #'N',(a0)+
    move.b  #'E',(a0)+
    move.b  #'G',(a0)+
    
    cmp.b   #%00,d3
    beq     size_b
    
    cmp.b   #%01,d3
    beq     size_w
    
    bra     size_l
    
jsr
    move.b  #'J',(a0)+
    move.b  #'S',(a0)+
    move.b  #'R',(a0)+
    move.b  #' ',(a0)+
    jsr     compute_address
    rts
    
*-----------------------------------To be fixed later--------------------------------------------    
muls
    move.b  #'M',(a0)+
    move.b  #'U',(a0)+
    move.b  #'L',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+

    jsr     get_source
    jsr     cut_opcode
    move.b  #',',(a0)+
    jsr     get_destination_register_bits
    move.b  d1,d3
    moveq   #0,d1
    lea     address_mode_jump_table,a5
    mulu    #8,d1
    jsr     (a5,d1)
    rts
divs
    move.b  #'D',(a0)+
    move.b  #'I',(a0)+
    move.b  #'V',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+

    jsr     get_source
    jsr     cut_opcode
    move.b  #',',(a0)+
    jsr     get_destination_register_bits
    move.b  d1,d3
    moveq   #0,d1
    lea     address_mode_jump_table,a5
    mulu    #8,d1
    jsr     (a5,d1)
    rts
cut_opcode
    lsl.w   #4,d0
    lsr.w   #4,d0
    rts

compute_address
    jsr     cut_opcode 
    jsr     get_source
    jsr     get_destination
    rts
*------------------------------------------------------------------------------------------------

or
    move.b  #'O',(a0)+
    move.b  #'R',(a0)+
    
    cmp.b   #0,d3
    beq     size_b
    
    cmp.b   #1,d3
    beq     size_w
    
    bra     size_l
    
ori
    move.b  #'O',(a0)+
    move.b  #'R',(a0)+
    move.b  #'I',(a0)+
    
    cmp.b   #0,d3
    beq     size_b
    
    cmp.b   #1,d3
    beq     size_w
    
    bra     size_l
    
    
size_b
    move.b  #'.',(a0)+
    move.b  #'B',(a0)+
    move.b  #' ',(a0)+
    move.b  #1,d7
    jsr     compute_address
    rts
    
size_w
    move.b  #'.',(a0)+
    move.b  #'W',(a0)+
    move.b  #' ',(a0)+
    move.b  #2,d7
    jsr     compute_address
    rts

size_l
    move.b  #'.',(a0)+
    move.b  #'L',(a0)+
    move.b  #' ',(a0)+
    move.b  #3,d7
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
    cmp.b   #1,d7
    simhalt
    beq     immediate_length_byte
    cmp.b   #2,d7
    beq     immediate_length_word
    bne     immediate_length_long
    rts
  
immediate_length_byte
    move.w  (a2)+,d0
    move.w  d0,d2
    lsl.w   #5,d2
    lsl.w   #3,d2
    lsr.w   #3,d2
    lsr.w   #6,d2
    lsr.w   #3,d2
    lea     hex_jump_table,a5
    mulu.w  #8,d2
    jsr     (a5,d2)
    move.w  d0,d1
    lsl.w   #6,d2
    lsl.w   #6,d2
    lsr.w   #6,d2
    lsr.w   #6,d2
    mulu.w  #8,d2
    jsr     (a5,d2)
    rts
    

immediate_length_word
    move.w  (a2)+,d0
    simhalt
    rts
    
immediate_length_long
    jsr     immediate_length_word
    jsr     immediate_length_word
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
    
 
buffer  dc.w    80
f_size  dc.b    160
f_name  dc.b    'opcodes.txt',0
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
s_notif dc.b    'Starting program deconstruction...'                                         ,cr,lf,0
endprog dc.b    'Finished deconstruction.'                                                   ,0
endinv  dc.b    'Something went very wrong...'                                               ,cr,lf
        dc.b    'Exiting the program.'                                                       ,0  

    end    start




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
