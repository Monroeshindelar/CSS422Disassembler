
*-----------------------------------------------------------
* Title      : Disassembler
* Written by : JJ Abides, Dan Florsecu, Monroe Shindelar
* Date       : November 9th 2017 
* Description: 
*-----------------------------------------------------------
cr      equ     $0d
lf      equ     $0a
paddr1  equ     $00FFFF00
minaddr equ     $00000000
maxaddr equ     $00FFFE00

start   org     $1000

*-----------------------------------------------------------
*				   Displaying Startup Message
*-----------------------------------------------------------
    
    lea     snp,a1                                  * Loading the gretting message onto the console
    move.b  #14,d0
    trap    #15 
    
*-----------------------------------------------------------
*				           User Input				
*-----------------------------------------------------------

    move.b  #2,d0                                   * Asking the console for input from the user
    trap    #15
    clr     d0
    jsr     convert_to_hex                          * Converting the input from ascii to hex
    jsr     prepare_to_load_address                 * Prepping the address to be loaded into an address register
    jsr     get_address                             * More converting of the user input
    jsr     check_addr_legality                     * Checks the user input for edge cases. Stops the program for bad input
    movea.l d2,a2                                   * Moves the converted address from the data register into the address register
                    
    lea     entend,a1                               * Asking the user for the ending address
    move.b  #14,d0
    trap    #15

    lea     $0000,a0
    lea     $0200,a1
    move.b  #2,d0                                   * Taking input from the user for the starting address
    trap    #15     
    clr     d0
    jsr     convert_to_hex                          * Converting the address from ascii to hex
    jsr     prepare_to_load_address                 * Preps the address for loading into the reg
    jsr     get_address                             * More address conversions
    jsr     check_addr_mismatch                     * Checks if the ending address is smaller than the starting address
    movea.l d2,a3                                   * Moves the ending address into the
    
                                    

    jsr     request_read_from_file                  * Ask the user if they want to load from a file

    
decode_start
    
    lea     s_notif,a1                              * Notify the user that the program has started deconstruction
    move.b  #14,d0                  
    trap    #15    

    jsr     clear_all_data_registers                * Clears out the data registers for clarity
    
loop                                                * Main loop to go through the user input range of addresses
    lea      $0000,a0       
    cmpa.l   a2,a3                                  * Checks to see if we have hit the end of out address range
    ble      done                                   * If the starting address is less than the ending address
    move.w   (a2)+,d0                               * Grabs the next opcode from memory
    jsr 	 evaluate_operation                     * Finds out what the opcode grabbed from memory is
    jsr      print                                  * Prints the opcode to the console
    bra      loop                                   * Start the loop again to go to the next opcode
    
*-----------------------------------------------------------
*				     Integrity Checks					
*-----------------------------------------------------------

check_addr_legality                                 * Checks to see if the input addresses are legal
    jsr     check_addr_size                         * Check if the addresses are proper size
    jsr     check_addr_even                         * Check to see if the address is even
    rts 
    
check_addr_size                                     * Method to check if the address input is not too small or large
    cmp.l   #minaddr,d2                             * Compare the input address to the minimum address
    blt     invalid                                 * If its smaller, end the program
    cmp.l   #maxaddr,d2                             * Compare the input address to the maximum address
    bgt     invalid                                 * If its larger, end the program
    rts         

check_addr_even                                     * Method to check if the address input is odd or not
    move.l  d2,d3                                   * Moves the input address into a new data register
    asr     #1,d3                                   * Shifts off the last bit on the address
    bcs     invalid                                 * If that last bit was a one, end the program
    rts

check_addr_mismatch                                 * Checks if the starting and ending address are not in correct order
    move.l  a2,d1                                   * Move the starting address into a data register
    move.l  a3,d3                                   * Move the ending address into a data register
    cmp.l   d1,d3                                   * Compare the two addresses
    bgt     invalid                                 * If the ending address is larger than the starting address, end the program
    rts  
    
*-----------------------------------------------------------
*                       Conversion                  
*-----------------------------------------------------------
convert_to_hex                                      * Method that converts data from ascii to hex
    move.b  (a1)+,d1                                * Moves a byte from memory into a data register for conversion
    beq     return_helper                           * If we have hit the null termination, we are done
    cmp.w   #$FF,d1                                 * If we have hit FF we are done
    beq     return_helper                                   
    addi.b  #1,d5                                   * Add one to d5 for some reason
    cmpi.b  #$30,d1                                 * Compare the data to 30, if its less, its bad data
    blt     invalid
    cmpi.b  #$66,d1                                 * Compare the data to 66, if its greater, its bad data
    bgt     invalid
    cmpi.b  #$39,d1                                 * Compare the data to 39, if its less than or equal to, its a number, convert it
    ble     convert_number_to_hex                   
    cmpi.b  #$61,d1                                 * Compare the data to 61, its ifs greater or equal, its lowercase, covert it
    bge     convert_lowercase_letter_to_hex     
    cmpi.b  #$46,d1                                 * Compare the data to 46, if its greater than, its bad data
    bgt     invalid
    cmpi.b  #$41,d1                                 * Compare the data to 41, if its greater than or equal to, its uppercase, convert it
    bge     convert_uppercase_letter_to_hex

convert_number_to_hex                               * Method to convert a number from ascii to hex
    subi.b  #$30,d1                                 * Subtract 30 from the ascii to get the hex
    move.b  d1,(a0)+                                * Add the hex number to a0
    bra     convert_to_hex                          * Go back and convert more stuff

convert_lowercase_letter_to_hex                     * Method to convert a letter from lowercase to hex
    subi.b  #87,d1                                  * Subtract 87 from it
    move.b  d1,(a0)+                                * Move the hex value to the next spot in a0
    bra     convert_to_hex                          * Go back and convert more stuff

convert_uppercase_letter_to_hex                     * Method to convert a letter called uppercase to hex
    subi.b  #55,d1                                  * Subtract 55 from the letter to get the hex
    move.b  d1,(a0)+                                * Move it into the next slot in a0
    bra     convert_to_hex                          * go back and convert more stuff

prepare_to_load_address                             * Method that prepares the address so it can be converted further
    clr     d0
    clr     d1
    clr     d2
    lea     $0000,a0
    rts

get_address                                         * Method that trims 0's from the ascii to hex address
    move.b  (a0)+,d1                                * Moves the ascii to hex address into a data register
    cmp.b   #0,d5                                   * Checks if its 0, if it is we can return
    beq     return_helper
    asl.l   #4,d2                                   * Shifts a nibble off
    add.b   d1,d2                                   * Adds d1 to d2
    subi.b  #1,d5                                   * Subtracts 1 from d5, cant really remember why i did this
    bra     get_address                             * Go back to convert the next byte
    
read_file                                           * Method to read a file of opcodes into memory for decoding
    lea     f_name,a1                               * Loads the filename into memory so 68k can read it
    move.b  #51,d0                                  
    trap    #15
    move.l  #f_size,d2                              * Load the filesize into d2, precondition for file reading
    lea     $500,a1
    move.b  #53,d0
    trap    #15
    movea.l a1,a6                                   
    movea.l a2,a4
    jsr     convert_file_contents                   * File is loaded in ascii, so this goes through all the file contents and converts it
    bra     decode_start                            * Goes back to the start of the program to start decoding
    
convert_file_contents                               * Method to convert the file contents from ascii to hex
    clr     d3              
    lea     $00a0,a0
    cmp.w   #0,d2                                   * D2 holds the number of bytes read, using it as a loop counter
    beq     return_helper                           * If we have converted all the bytes, go back
    move.w  (a1)+,d0                                * Move the next word into a data register for decoding
    move.w  a1,d7                                   * Save the address so we can reload it
    lea     $0010,a1                                
    move.w  d0,(a1)
    jsr     convert_to_hex                          * Call convert to hex on whatever we just pulled from memory
    clr     d0
    move.b  #2,d5                                   * Really cant remember why im doing this
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
   
request_read_from_file                              * Method to request a read froma file
    lea     reqf,a1                                 * Ask the user if they want to read from a file
    move.b  #14,d0
    trap    #15
    
    move.b  #2,d0                                   * Take the input
    trap    #15
    
    move.b  (A1),d1                                 * Check if the input was a yes or a no
    cmpi.b  #$79,d1
    beq     warn_file                               * If they said yes, Load a warnning and make sure they want to load froma file
    cmpi.b  #$59,d1
    beq     warn_file
    cmpi.b  #$6e,d1
    beq     decode_start
    cmpi.b  #$4e,d1
    beq     decode_start
    bra     request_read_from_file                  
    
warn_file                                           * File reading warning
    lea     warnf,a1                                * Load the file reading warning to the user
    move.b  #14,d0
    trap    #15
    
    move.b  #2,d0                                   * Ask the user for their input
    trap    #15
    
    move.b  (A1),d1                                 * Checks the users input
    cmpi.b  #$79,d1
    beq     read_file
    cmpi.b  #$59,d1
    beq     read_file
    cmpi.b  #$6e,d1
    beq     decode_start
    cmpi.b  #$4e,d1
    beq     decode_start
    bra     warn_file
    
print                                               * Prints the currently decoded opcode to the console
    move.b  #$00,(a0)                               * Adds null termination to the op code
    lea     $0000,a1                                * Loads the address where the opcode is stored
    moveq   #13,d0                                  * Print the opcode
    trap    #15
    move.b  #16,d5
    lea     $0000,a0
    move.b  #30,d1
    jsr     check_page_count                        * Check if the page is full
    jsr     clear_address                           * Clear out the address for the next opcode
    rts
    
check_page_count                                    * Checks if we have filled the console with prints
    lea     paddr1,a4                               * Loads print counter into mem
    addi.b  #$1,(a4)                                * Adds one to the print counter
    cmpi.b  #$1e,(a4)                               * Compares the print counter to 30
    beq     halt_print                              * If we have reached 30, stop printing until the user tells you to start again                                              
    rts
    
halt_print                                          * Method that stops the printing and asks for user input
    lea     nx_pge,a1                               * Loads the next page message
    move.b  #14,d0                                  
    trap    #15
    
    move.b  #2,d0                                   * Asks for the user input
    trap    #15 
    
    cmpi.b  #$2,d0                                  * If its enter, go to print the next page
    beq     continue_print                          
    bra     halt_print                              * If its not enter, wait till it is
    
continue_print                                      * Method to print the next page
    lea     empty,a1                                * Loads an empty string to start the new page
    move.b  #14,d0
    trap    #15
    
    lea     nx_pge,a4                               * Restarts the page counter
    move.l  #$00000000,(a4)
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
    
clear_address                                       * Method to clear out an address. Clears out the address at a0
    cmp.b   #0,d5                                   * Compares loop counter to 0 to check if we are done
    beq     return_helper
    move.b  #$FF,(a0)+                              * Wipe the data at the current location in memory
    subi.b  #1,d5                                   * Substract one from the loop counter
    bra     clear_address                           * Keep going
    
invalid                                             * Method to end the program when something bad happens
    lea     endinv,a1                               * Loads an error onto the console
    move.b  #14,d0                                  
    trap    #15
    bra     exit_prog                               * Exits the program

done                                                * Method to be called when the program is done executing
    lea     endprog,a1                              * Loads the successful message onto the console
    move.b  #14,d0
    trap    #15                                     
    
exit_prog                                           * Method that exits the program
    move.b  #9,d0
    trap    #15                                     * Exits the program



evaluate_operation
    jsr     get_op_code                 * Gets the full 16 bit opcode for disassembling
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
    beq     check_4                     * Branch to code that checks through a set of opcodes with #4 as their start (big endian)
                                    
                                    
    cmp.b   #%1101,d1                   * Check for ADD, ADDA
    beq     check_add_type
    
    cmp.b   #%1001,d1                   * Check for SUB
    beq     check_sub_type
    
    cmp.b   #%0101,d1                   * Check for SUBQ: Check first 4 bits then diferentiate between other opcodes with the same 4 bits
    beq     check_subq
    
    cmp.b   #$8,d1
    beq     check_8                     * Check if the opcode is DIVS or OR
    
    cmp.b   #$C,d1
    beq     check_muls                  * Check if the opcode is MULS
    
    cmp.b   #0,d1                       * Check for ORI, CMPI, and BCLR
    beq     check_0
    
    cmp.b   #$B,d1
    beq     check_b                     * Check if EOR or CMP
    
    cmp.b   #$E,d1
    beq     check_e                     * Check for ASd, LSd, or ROd
    
    cmp.b   #$6,d1
    beq     check_6                     * Check for Bcc or BRA
    
    bra     data                        * Otherwise, it's data

check_move_type                         * Check the type of MOVE: MOVE or MOVEA
    move.b  #0,d4 
    move.b  d1,d3                       * store size of move
    jsr     get_source_mode_bits
    
    cmp.b   #5,d1                       * If the source mode is displacement (101 or 110), it's data
    beq     data
    
    cmp.b   #6,d1                       
    beq     data

    
    cmp.b   #%111,d1                    * If source mode bits are 111
    beq     check_move_source_register 
    
    
continue_move_check                     
    jsr     get_destination_mode_bits
    cmp.b   #%001,d1
    beq     moveA                       * If destination mode bits are 001, it's MOVEA
    
    cmp.b   #%111,d1
    beq     check_move_destination_register    * If destination mode is 111, check the register for validity
    
    bra     move                        *Otherwise, it's a valid MOVE

check_move_destination_register             * This label checks for valid destination register bits when mode bits are 111
    jsr     get_destination_register_bits
    cmp.b   #%001,d1                        * destination register bits cannot be more than 1 for valid instruction
    bgt     data
    
    bra     move                          * Otherwise, it's a valid MOVE
    
check_move_source_register          
    jsr     get_source_register_bits
    cmp.b   #%010,d1                    * when source mode bits are 111, source register bits cannot be 2,3, or bigger than 4.
    beq     data
    
    cmp.b   #%011,d1
    beq     data
    cmp.b   #4,d1
    bgt     data
    
    bra    continue_move_check          * Otherwise, it's a valid move
    

check_add_type                              * This label checks for the type of ADD: ADD or ADDA
    jsr     get_destination_mode_bits
    move.b  d1,d3                           *Storing size in d3
    
    lsl.b   #6,d3                           *Isolating size bits
    lsr.b   #6,d3
    lsr.b   #2,d1                           *Isolating direction bit in D1
    
    cmp.b   #%11,d3
    beq     check_addA_mode                 * If size bits are 11, it's ADDA
    
    cmp.b   #1,d1                           * If directional bit is 1 (EA Destination), check available addressing modes for that
    beq     add_EA_destination_type
    
    jsr     get_source_mode_bits           * Otherwise, it uses a data register as the destination (<ea> + Dn -> Dn), so check the available addressing for that
    cmp.b   #5,d1                          * Same as before in MOVE, check for displacement mode bits (5 and 6)
    beq     data
    
    cmp.b   #6,d1                   
    beq     data    

    cmp.b   #1,d1                           * if the addressing mode is 1 (address register direct), check for a valid size
    beq     check_valid_add_size
    
    cmp.b   #%111,d1                        * If mode is 111, check source register bits for validity
    beq     check_add_source_register
    
       
    bra     add                             *Otherwise it's just ADD
    
check_valid_add_size
    cmp.b   #0,d3
    beq     data                            * size of ADD in address mode direct (001) cannot be a byte (opmode :000)
    
    bra     add
    
add_EA_destination_type                     * This label checks for valid source modes when the destination is <EA> type (directional bit is 1)
    jsr     get_source_mode_bits
    cmp.b   #5,d1                           * checking for displacement modes (5 and 6)
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1
    ble     data                            * If source mode bits are less than or equal to 1, it's invalid
    
    cmp.b   #%111,d1
    beq     check_add_source_registerEA     * Checks available register bits for mode 111 in EA Destination mode
    
    bra     add                             * Otherwise, it's a legit ADD
    
check_add_source_registerEA                 * checks the source register when mode is 111 in EA destination mode
    jsr     get_source_register_bits
    cmp.b   #%01,d1
    bgt     data                            * register bits cannot be greater than 1
    
    bra     add                             * otherwise it's a valid ADD
    
check_add_source_register                   * checks the source register when mode is 111
    jsr     get_source_register_bits
    cmp.b   #%010,d1                        * bits cannot be 2 or 3 (displacement)
    beq     data
    
    cmp.b   #%011,d1
    beq     data
    
    cmp.b   #4,d1                           *If register bits is greater than 4, it's DATA
    bgt     data
    
    
    bra     add                             * Otherwise, it's a valid ADD
    
check_addA_mode
    move.b  d1,d3                           * Move the size bit into d3
    jsr     get_source_mode_bits
    cmp.b   #5,d1                           * The same displacement mode check here
    beq     data
    
    cmp.b   #6,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_addA_source_register      * If mode bits are 111, validate the register bits
    
    bra     addA                            * Else, it's a legit ADDA
    
check_addA_source_register
    jsr     get_source_register_bits
    cmp.b   #%010,d1                        * The same displacement mode check here for register checking when mode is 111
    beq     data
    
    cmp.b   #%011,d1
    beq     data

    cmp.b   #4,d1
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
    
    jsr     get_source_mode_bits  * Otherwise, it uses a data register as the destination (Dn - <ea> -> Dn), so check the available addressing for that

    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data
    
    cmp.b   #1,d1
    beq     check_valid_sub_size            * check for a valid sub size
    
    cmp.b   #%111,d1                        * If mode is 111, check source register bits for validity
    beq     check_sub_source_register
  
    bra     sub                             *Otherwise it's just SUB
    
check_valid_sub_size                        * If addressing mode is address mode direct (001) cannot have byte size
    cmp.b   #0,d3
    beq     data
    
    bra     sub

sub_EA_destination_type                     * This label checks for valid source modes in EA destination type (direcitonal bit == 1)
    jsr     get_source_mode_bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1
    ble     data                            * If mode bits are less than or equal to 1, it's invalid
    
    cmp.b   #%111,d1
    beq     check_sub_source_registerEA
    
    bra     sub

check_sub_source_registerEA                 * This label checks for valid source registers in EA destination type when mode is 111
    jsr     get_source_register_bits
    cmp.b   #%001,d1                        * Register bits cannot be bigger than 1 for valid instruction
    bgt     data
    
    bra     sub                             
    
check_sub_source_register                   * This label is used to check the source register for Data register destination type when mode is 111
    jsr     get_source_register_bits
    cmp.b   #%010,d1
    beq     data
    
    cmp.b   #%011,d1
    beq     data

    cmp.b   #%100,d1
    bgt     data
    
    bra     sub
    
check_subq                              * Label for checking valid subq opcode
    jsr     get_destination_mode_bits
    move.b  d1,d3
    lsl.b   #6,d3                       * Isolating size bits
    lsr.b   #6,d3                       * Storing size in d3
    cmp.b   #%11,d3                     * If size was 11, it's invalid because those bits are reserved for Scc and DBcc, which are not supported
    beq     data
    
    lsr.b   #2,d1                       * Isolating the last bit of the destination mode
    cmp.b   #0,d1                       * If bit was 0, it's ADDQ which is not supported
    beq     data
    
    jsr     get_source_mode_bits        * Check for displacement bits here
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data
 
    cmp.b   #%111,d1                    * Now checking if the source mode bits is 111
    beq     check_subq_source_register  * check for valid registers
    
    bra     subq                        * Otherwise it's a legit subq
 
check_subq_source_register
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data                        * If register bits are greater than 1, it's invalid
    
    bra     subq                        * Otherwise it's a legit subq
    
check_4                                 * Supported 0100 opcodes: MOVEM, LEA, NEG, and JSR
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
    lsl.w   #7,d1                       * This is suppose to be a very weird AND operation for determining MOVEM
    add.b   d1,d3                       * What's happening is that I take the 2 bits (big endian) of the destination mode
                                        * take the first bit of the destination register by collecting the destination register bits as a whole word,
    lsl.w   #8,d1                       * shifting it to the left (byte range) 7 times (shifting the last 2 register bits out of byte range),
    lsl.b   #2,d1                       * then adding (byte range) it to the 2 destination mode bits
    add.b   d1,d3                       * Then I shift the 2 bits back into byte range and isolate the last bit (from the left) and add that as well
    
    cmp.b   #%10,d3                     * What this results in is a unique value that cannot be obtained from any other 0100 opcode, besides MOVEM and EXT
    beq     check_moveM                 * Since we've reduced it down to MOVEM and EXT, the program does further checks to see if it is a legit MOVEM
    
    
    bra     data                        * Otherwise, it's invalid


check_neg                               * The NEG checker
    jsr     get_destination_mode_bits
    cmp.b   #%11,d1
    beq     data                        * If size bits is %11, it's invalid
    
    move.b  d1,d3                       * store the size in d3
    jsr     get_source_mode_bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

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
    

check_jsr                               * The JSR checker
    jsr     get_source_mode_bits
    cmp.b   #%010,d1                    * Valid mode bits are 010, 101, 110, and 111 with specific register bits
    beq     jsr
    
    cmp.b   #%111,d1
    beq     check_jsr_source_register   * If 111, check register bits for validity
    
    bra     data                        * Otherwise, it's invalid

check_jsr_source_register
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data                        * If register bits is over 3, it's invalid
    
    bra     jsr                         * Otherwise, it's a valid JSR
    
    
check_lea                               * The LEA checker
    jsr     get_source_mode_bits
    cmp.b   #%010,d1
    beq     lea
    
    cmp.b   #%111,d1
    beq     check_lea_source_register   * check lea's source regiser bits if mode is 111
    
    bra     data                        * Otherwise it's invalid               
    
check_lea_source_register
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data                        * If register bits is greater than 3, it's invalid
    
    bra     lea                         * Otherwise it's a valid LEA

check_movem
    jsr     get_source_mode_bits
    move.b  d1,d3
    cmp.b   #%010,d3                    * if source mode bits is #2, it's a valid MOVEM
    beq     moveM
    
    jsr     get_destination_register_bits
    lsl.b   #6,d1
    lsr.b   #7,d1                       * Isolate the directional bit
    
    cmp.b   #%111,d3
    beq     check_moveM_reg             * Check the register bits for validity if mode bits are 111
    
    cmp.b   #1,d1
    beq     moveM_memToReg              * If the directional bit is 1, it's memory to register mode
    
    cmp.b   #%100,d3                    * If it's not, it's in register to memory mode, which has access to predecrement address register indirect
    beq     moveM                       * if it's bits are #4, it's a valid moveM
    
    bra     data                        * Otherwise, it's not MOVEM

check_moveM_reg                         *This section checks the direction if it's memory to register. If not, it checks for valid register to memory 111 address modes
    jsr     get_source_register_bits
    cmp.b   #1,d1                       *If register bits are greater than 1, it's DATA
    bgt     data
    
    bra     moveM                       * Otherwise, it's a legit MOVEM
    

moveM_memToReg                          * This section checks addressing modes that are available in memory to register mode (excluding 111 mode)
    cmp.b   #%011,d3
    beq     moveM
    
    bra     data                        * otherwise it's not MOVEM
    
                                        *------------------------------------------------------------------------------------------------
                                        * NOTE: At this point, most of the decoding code for each opcode becomes very similar, 
                                        * so some comments are unnecessary for explanation.
                                        *------------------------------------------------------------------------------------------------
                                        
                                        
check_8                                 * This label checks for opcodes with 8 as their starting hex
    jsr     get_destination_mode_bits
    cmp.b   #%111,d1
    beq     check_divs                  * Check if it's a valid DIVS
    
    cmp.b   #%011,d1
    bne     check_or                    * check if it's a valid OR
    
    bra     data                        * Otherwise, it's invalid
    rts

check_divs
    jsr     get_source_mode_bits        * Like before, checking for displacement mode bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1                    * DIVS does not support address mode direct as a source
    beq     data
    
    cmp.b   #%111,d1                    * If mode bits are 111, check for valid register bits
    beq     check_divs_source_register
    
    bra     divs                        * Otherwise it's a valid DIVS
    
check_divs_source_register
    jsr     get_source_register_bits    * Check for valid register bits here when mode bits are 111
    cmp.b   #%010,d1
    beq     data
    
    cmp.b   #%011,d1
    beq     data

    cmp.b   #%100,d1
    bgt     data
    
    bra     divs
    
    
check_muls                                * This label checks for a valid MULS instruction
    jsr     get_destination_mode_bits
    cmp.b   #%111,d1                    
    beq     check_muls_source_mode        * If destination mode bits is 111, it's most likely MULS. Check the source mode for valid EA modes
    bne     data
    rts
    
check_muls_source_mode
    jsr     get_source_mode_bits          * Same displacement-checking code as before
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1                        * MULS does not support address register direct
    beq     data
    
    cmp.b   #%111,d1
    beq     check_muls_source_register      * If source mode bits are 111, check source register bits for validity
    
    bra     muls
    
check_muls_source_register
    jsr     get_source_register_bits    * Same displacement-checking code as before, and no register bits exist above 4 for valid 111 modes
    cmp.b   #%010,d1
    beq     data
    
    cmp.b   #%011,d1                    
    beq     data

    cmp.b   #%100,d1                    
    bgt     data
    
    bra     muls
                                            
check_or                                    * Label for checking OR
    move.b  d1,d3
    lsl.b   #6,d3
    lsr.b   #6,d3                           * getting size by shifting and isolating first 2 bits(little endian)
    
    lsr.b   #2,d1                           * Isolate direction bit
    
    cmp.b   #1,d1                           * If direction bit is 1, location is destination operand, otherwise, location is source operand
    beq     check_or_destination_operand
    
    jsr     get_source_mode_bits            * Displacement checking code
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1                        * OR does not support address mode direct
    beq     data
    
    cmp.b   #%111,d1    
    beq     check_or_source_register0       * Checking register bits in 111 mode
    
    bra     or
    
check_or_source_register0                   * Label for checking register bits in 111 mode in direction 0
    jsr     get_source_register_bits        * Displacement-checking code for 111 mode, and code for checking register bits greater than 4
    cmp.b   #%010,d1
    beq     data
    
    cmp.b   #%011,d1
    beq     data

    cmp.b   #%100,d1            
    bgt     data
    
    bra     or
    
check_or_destination_operand                * Label for checking when OR is in destination operand mode (direction bit is 1)
    jsr     get_source_mode_bits
    cmp.b   #5,d1                           * Displacement checking code
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1
    ble     data
    
    cmp.b   #%111,d1
    beq     check_or_source_register1
    
    bra     or

check_or_source_register1
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data
    
    bra     or

check_0                                        * This label checks for opcodes that start with 0000
    move.w  d0,d1
    lsr.w   #6,d1
    
    cmp.b   #$22,d1
    beq     check_bclr                         * Check if valid BCLR (static)
    move.b  d1,d3
    
    jsr     get_destination_mode_bits
    cmp.b   #%110,d1
    beq     check_bclr                         * Check if valid BCLR (dynamic)
    
    lsr.w   #2,d3
    
    cmp.b   #0,d3
    beq     check_ori                          * Check if valid ORI
    
    cmp.b   #$C,d3
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
    
check_bclr                                      * checks for valid source modes in BCLR static
    jsr     get_source_mode_bits                
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1                            * cannot use direct address mode
    beq     data
    
    cmp.b   #%111,d1
    beq     check_bclr_source_register
    
    bra     bclr
    
check_bclr_source_register
    jsr     get_source_register_bits
    cmp.b   #1,d1
    bgt     data
    
    bra     bclr
    
check_cmpi
    jsr     get_destination_mode_bits
    cmp.b   #%11,d1
    beq     data                                * size cannot be 011 for CMPI
    
    move.b  d1,d3
    
    jsr     get_source_mode_bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_cmpi_source_register
    
    bra     cmpi
    
check_cmpi_source_register
    jsr     get_source_register_bits
    cmp.b   #%001,d1
    bgt     data
    
    bra     cmpi
    
check_b
    jsr     get_destination_mode_bits
    ror.w   #2,d1
    cmp.b   #1,d1
    beq     check_eor
    
    bra     check_cmp
    
check_eor
    rol.w   #2,d1
    cmp.b   #%111,d1
    beq     data                               * For EOR, size cannot be 111
    
    move.b  d1,d3
    
    jsr     get_source_mode_bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1
    beq     data
    
    cmp.b   #%111,d1
    beq     check_eor_source_register
    
    bra     eor
    
check_eor_source_register
    jsr     get_source_register_bits
    cmp.b   #1,d1
    bgt     data
    
    bra     eor

check_cmp
    rol.w   #2,d1
    cmp.b   #%011,d1
    beq     data
    
    move.b  d1,d3
    
    jsr     get_source_mode_bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%111,d1
    beq     check_cmp_source_register
    
    cmp.b   #%001,d1
    beq     check_legit_cmp_size
    
continue_cmp
    
    bra     cmp
    
check_legit_cmp_size
    cmp.b   #0,d3
    beq     data                        * If using address register direct, cannot have byte size for CMP
    
    bra     continue_cmp
    
check_cmp_source_register
    jsr     get_source_register_bits
    cmp.b   #%010,d1
    beq     data
    
    cmp.b   #%011,d1
    beq     data

    cmp.b   #%100,d1
    bgt     data
    
    bra     cmp

check_e                                     * This is a label for checking ASL/ASR, LSL/LSR, and ROL/ROR
    jsr     get_destination_mode_bits
    lsl.b   #6,d1
    lsr.b   #6,d1                           * Isolate the size bits
    
    cmp.b   #%11,d1                         * If size bit is 11, it's a memory shift type
    beq     check_memory_shift_type
    
    move.b  d1,d3                           * Else, it's register shift type. Store size in d3
    jsr     get_source_mode_bits
    lsl.b   #6,d1
    lsr.b   #6,d1                           * Isolate the size bits (again) for register shift opcode type
    cmp.b   #%00,d1
    beq     check_asd_register_shift
    
    cmp.b   #%01,d1
    beq     check_lsd_register_shift
    
    cmp.b   #%11,d1
    beq     check_rod_register_shift
    
    bra     data
    
check_asd_register_shift
    jsr     get_destination_mode_bits
    lsr.b   #2,d1
    
    bra     asd
    
check_lsd_register_shift
    jsr     get_destination_mode_bits
    lsr.b   #2,d1
    
    bra     lsd
    
check_rod_register_shift
    jsr     get_destination_mode_bits
    lsr.b   #2,d1
    
    bra     rod
    
check_memory_shift_type
    move.b  d1,d3
    jsr     get_destination_register_bits
    cmp.b   #%000,d1
    beq     check_asd_memory_shift
    
    cmp.b   #%001,d1
    beq     check_lsd_memory_shift
    
    cmp.b   #%011,d1
    beq     check_rod_memory_shift
    
    bra     data
    
check_asd_memory_shift
    jsr     check_memory_shift_mode
    
    cmp.b   #%111,d1
    beq     check_asd_memory_shift_register
    
    bra     asd
    
check_lsd_memory_shift
    jsr     check_memory_shift_mode
    
    cmp.b   #%111,d1
    beq     check_lsd_memory_shift_register
    
    bra     lsd
check_rod_memory_shift
    jsr     check_memory_shift_mode
    
    cmp.b   #%111,d1
    beq     check_rod_memory_shift_register
    
    bra     rod

check_memory_shift_mode                                 * checks for valid mode bits
    jsr     get_source_mode_bits
    cmp.b   #5,d1
    beq     data
    
    cmp.b   #6,d1
    beq     data

    cmp.b   #%001,d1
    ble     data
    
    rts     

check_asd_memory_shift_register                        *checks asd memory shift type source register when mode is 111
    jsr     get_source_register_bits
    cmp.b   #1,d1
    bgt     data
    
    bra     asd
    
check_lsd_memory_shift_register                        *checks lsd memory shift type source register when mode is 111
    jsr     get_source_register_bits
    cmp.b   #1,d1
    bgt     data
    
    bra     lsd
    
check_rod_memory_shift_register                        *checks rod memory shift type source register when mode is 111
    jsr     get_source_register_bits
    cmp.b   #1,d1
    bgt     data
    
    bra     rod

check_6                                                 * This is a label for checking 0110 opcodes (the branching codes)
    move.w  d0,d1
    lsr.w   #8,d1
    
    cmp.b   #$60,d1
    beq     check_bra
    
    cmp.b   #$61,d1
    beq     data
    
    bra     check_Bcc_type
    
check_bra
    move.w  d0,d1
    jsr     get_displacement

    cmp.b   #$FF,d1                                     *If displacement value is FF, it's data (we don't support long)

    beq     data
    
    bra     bra                                         * Otherwise, it's a legit branch type

check_Bcc_type                                          * By checking the first 8 bits (big endian) we can determine what branch type it is
    cmp.b   #$65,d1
    beq     check_bcs
    
    cmp.b   #$6C,d1
    beq     check_bge
    
    cmp.b   #$6D,d1
    beq     check_blt
    
    cmp.b   #$68,d1
    beq     check_bvc
    
    bra     bcc_data
    
check_bcs
    move.w  d0,d1
    cmp.b   #$FF,d1
    beq     data
    
    bra     bcs
    
check_bge
    move.w  d0,d1
    cmp.b   #$FF,d1
    beq     data
    bra     bge

check_blt
    move.w  d0,d1

    cmp.b   #$FF,d1
    beq     data
    
    bra     blt

check_bvc
    move.w  d0,d1

    cmp.b   #$FF,d1
    beq     data
    
    bra     bvc
    
bcc_data
    jsr     data
    move.w  (a2)+,d0
    rts
    
*-----------------------------------------------------------
*                        OP Codes 			 				
*-----------------------------------------------------------
data
    move.b  #'D',(a0)+
    move.b  #'A',(a0)+
    move.b  #'T',(a0)+
    move.b  #'A',(a0)+
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
    
    move.b  #7,d4
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
    
    move.b  #8,d4

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
    
    move.b  #6,d4
    
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
    
    move.b  #7,d4
    
    cmp.b   #0,d3
    beq     size_w
    
    bra     size_l

sub
    move.b  #'S',(a0)+
    move.b  #'U',(a0)+
    move.b  #'B',(a0)+
    
    move.b  #6,d0
    
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
    
    move.b  #4,d4
    
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
    
    move.b  #7,d4
    lea     compute_address_jump_table,a5
    mulu    #8,d4
    jsr     (a5,d4)
    rts
    
neg
    move.b  #'N',(a0)+
    move.b  #'E',(a0)+
    move.b  #'G',(a0)+
    
    move.b  #1,d4
    
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
    
    jsr     get_source_register_bits
    move.b  d1,d3
    jsr     get_source_mode_bits
    mulu    #8,d1
    lea     address_mode_jump_table,a5
    jsr     (a5,d1)
    rts
    
muls
    move.b  #'M',(a0)+
    move.b  #'U',(a0)+
    move.b  #'L',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+
    move.b  #5,d4
    lea     compute_address_jump_table,a5
    mulu    #8,d4
    jsr     (a5,d4)
    rts
    
divs
    move.b  #'D',(a0)+
    move.b  #'I',(a0)+
    move.b  #'V',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+
    
    move.b  #5,d4
    lea     compute_address_jump_table,a5
    mulu    #8,d4
    jsr     (a5,d4)
    rts

or
    move.b  #'O',(a0)+
    move.b  #'R',(a0)+
    
    move.b  #6,d4
    
    cmp.b   #0,d3
    beq     size_b
    
    cmp.b   #1,d3
    beq     size_w
    
    bra     size_l
    
ori
    move.b  #'O',(a0)+
    move.b  #'R',(a0)+
    move.b  #'I',(a0)+
    
    move.b  #3,d4
    
    cmp.b   #0,d3
    beq     size_b
    
    cmp.b   #1,d3
    beq     size_w
    
    bra     size_l
    
bclr
    move.b  #'B',(a0)+
    move.b  #'C',(a0)+
    move.b  #'L',(a0)+
    move.b  #'R',(a0)+

    jsr     get_destination_mode_bits
    lsr.b   #2,d1

    cmp.b   #%1,d1
    beq     bclr_dynamic
    bne     bclr_static
    
    rts


bclr_static
    move.b  #3,d4
    
    jsr     get_source_mode_bits
    cmp.b   #0,d1
    beq     size_l
    
    bra     size_b
  
    rts

bclr_dynamic
    move.b  #8,d4
    jsr     get_source_mode_bits
    cmp.b   #0,d1
    beq     size_l
    
    bra     size_b
 
    
cmpi
    move.b  #'C',(a0)+
    move.b  #'M',(a0)+
    move.b  #'P',(a0)+
    move.b  #'I',(a0)+
    
    move.b  #3,d4
    
    cmp.b   #%00,d3
    beq     size_b
    
    cmp.b   #%01,d3
    beq     size_w
    
    bra     size_l

eor
    move.b  #'E',(a0)+
    move.b  #'O',(a0)+
    move.b  #'R',(a0)+
    
    move.b  #6,d4
    
    cmp.b   #%100,d3
    beq     size_b
    
    cmp.b   #%101,d3
    beq     size_w
    
    bra     size_l
    
cmp
    move.b  #'C',(a0)+
    move.b  #'M',(a0)+
    move.b  #'P',(a0)+
    
    move.b  #5,d4
    
    cmp.b   #%00,d3
    beq     size_b
    
    cmp.b   #%01,d3
    beq     size_w
    
    bra     size_l
    
    
asd
    move.b  #'A',(a0)+
    move.b  #'S',(a0)+
    
    move.b  #4,d4
    
    jsr     check_direction
    bra     check_shift_size

lsd
    move.b  #'L',(a0)+
    move.b  #'S',(a0)+
    
    move.b  #4,d4
    
    jsr     check_direction
    bra     check_shift_size

rod
    move.b  #'R',(a0)+
    move.b  #'O',(a0)+
    
    move.b  #4,d4
    
    jsr     check_direction
    bra     check_shift_size
    
bra
    move.b  #'B',(a0)+
    move.b  #'R',(a0)+
    move.b  #'A',(a0)+
    

    move.b  #2,d4
    
    cmp.b   #$00,d1
    beq     size_w
    
    bra     size_s
    
bcs
    move.b  #'B',(a0)+
    move.b  #'C',(a0)+
    move.b  #'S',(a0)+

    move.b  #2,d4
    
    
    cmp.b   #$00,d1
    beq     size_w
    
    bra     size_s

    
bge
    move.b  #'B',(a0)+
    move.b  #'G',(a0)+
    move.b  #'E',(a0)+
    
    move.b  #2,d4
    
    cmp.b   #$00,d1
    beq     size_w
    
    bra     size_s
    
blt
    move.b  #'B',(a0)+
    move.b  #'L',(a0)+
    move.b  #'T',(a0)+
    

    move.b  #2,d4
    
    cmp.b   #$00,d1
    beq     size_w
    
    bra     size_s
    
    
bvc
    move.b  #'B',(a0)+
    move.b  #'V',(a0)+
    move.b  #'C',(a0)+
    

    move.b  #2,d4

    cmp.b   #$00,d1
    beq     size_w
    
    bra     size_s

    
return_to_sub
    move.b  #'R',(a0)+
    move.b  #'T',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+
    rts
    

check_shift_size
    cmp.b   #%01,d1
    beq     size_w
    
    cmp.b   #%01,d1
    beq     size_w
    
    cmp.b   #%00,d1
    beq     size_b
    
    bra     size_l
    

check_direction
    cmp.b   #0,d1
    beq     right
    
    bra     left

right
    move.b  #'R',(a0)+
    rts
    
left
    move.b  #'L',(a0)+
    rts
    
size_b
    move.b  #1,d6
    move.b  #'.',(a0)+
    move.b  #'B',(a0)+
    move.b  #' ',(a0)+
    lea     compute_address_jump_table,a5
    mulu    #8,d4
    jsr     (a5,d4)
    rts
    
size_w
    move.b  #2,d6
    move.b  #'.',(a0)+
    move.b  #'W',(a0)+
    move.b  #' ',(a0)+
    lea     compute_address_jump_table,a5
    mulu    #8,d4
    jsr     (a5,d4)
    rts

size_l
    move.b  #3,d6
    move.b  #'.',(a0)+
    move.b  #'L',(a0)+
    move.b  #' ',(a0)+
    lea     compute_address_jump_table,a5
    mulu    #8,d4
    jsr     (a5,d4)
    rts
    
size_s
    move.b  #'.',(a0)+
    move.b  #'S',(a0)+
    move.b  #' ',(a0)+
    rts

*-----------------------------------------------------------
*             Effective Addressing Helper Methods				 				
*-----------------------------------------------------------
get_op_code                                         * Gets the first four bits of the op code for identification
    move.w  d0,d1                                   * Puts a copy of the full operation into d1
    lsr     #8,d1                                   * Shifts off a byte from the right side of the op code
    lsr     #4,d1                                   * Shifts off a nibble from the right side
    rts
    
cut_opcode                                          * Returns an op code where the first nibble is removed. For easier EA
    lsl.w   #4,d0                                   * Shifts off a nibble from the left
    lsr.w   #4,d0                                   * Shifts off a nibble from the right
    rts
    
get_source                                          * Method to get the source of an op code where it has the traditional 3 bits for M and 3 bits for Xn
    lea     address_mode_jump_table,a5              * Loads the address jump table into memory
    jsr     get_source_register_bits                * Gets the last three bits from the opcode
    move.b  d1,d3                                   * Moves them into d3
    jsr     get_source_mode_bits                    * Gets the next 3 bits to get the mode
    mulu    #8,d1                                    
    jsr     (a5,d1)                                 * Finds out the source mode and goes to that place in the jump table
    rts

get_destination                                     * Method to get the destination of an op code where it has the traditional 3 bits for M and 3 bits for Xn
    lea     address_mode_jump_table,a5              * Loads the address jump table into memory
    jsr     get_destination_register_bits           * Gets the middle/left three bits from the opcode
    move.b  d1,d3                                   * Moves them into d3
    jsr     get_destination_mode_bits               * Gets the leftmost 3 bits for the desetination mode
    mulu    #8,d1
    jsr     (a5,d1)                                 * Finds out what the sourcemode is and does the proper thing
    rts
    
get_destination_register_bits                       * Gets the 3 leftmost bits from the opcode after the first nibble has been cut
    move.w  d0,d1                                   * Moves a copy of the opcode into the first data register
    lsl.w   #4,d1                                   * Shifts off a nibble from the left
    lsr.w   #8,d1                                   * Shifts off a byte from the right
    lsr.w   #5,d1                                   * Shifts off a nibble + 1 from the right
    rts
 
get_destination_mode_bits                           * Gets the middle/left 3 bits from the opcode after the first nibble has been cut
    move.w  d0,d1                                   * Moves a copy of the opcode into the first data register
    lsl.w   #7,d1                                   * Shifts off one less than a byte from the left
    lsr.w   #8,d1                                   * Shifts off a byte from the right
    lsr.w   #5,d1                                   * Shifts off a nibble + 1 from the right
    rts

get_source_mode_bits                                * Gets the middle/rightmost 3 bits from the opcode after the first nibble has been cut
    move.w  d0,d1                                   * Moves a copy from d1 to d2
    lsl.w   #6,d1                                   * Shifts off a nibble and a half from the left
    lsl.w   #4,d1                                   * Shifts off a nibble from the right
    lsr.w   #8,d1                                   * Shifts off a byte from the right
    lsr.w   #5,d1                                   * Shifts off a nibble + 1 from the right
    rts
    
get_source_register_bits                            * Gets the rightmost 3 bits from the opcode after the first nibble has been cut
    move.w  d0,d1                                   * Moves a copy into d1
    lsl.w   #8,d1                                   * Shifts a byte off the left
    lsl.w   #5,d1                                   * Shifts a nibble + 1 off the left
    lsr.w   #8,d1                                   * Shifts a byte off the right
    lsr.b   #5,d1                                   * Shifts a nibble + 1 off the right
    rts
    
get_direction_bit                                   * Gets the direction bit for things like add and sub
    move.w  d0,d1                                   * Moves a copy into d1
    jsr     get_destination_mode_bits               * Gets the 3 bits where the destination bit lies
    lsr.b   #2,d1                                   * Shift off the two unecessary ones
    rts                                     
    
get_displacement                                    * Method to get the displacement for things like BRA                                   
    lsl.l   #8,d1                                   * Shift a byte off the left
    lsl.l   #8,d1                                   * Shift a byte off the left
    lsl.l   #8,d1                                   * Shift a byte off the left
    lsr.l   #8,d1                                   * Shift a byte off the right
    lsr.l   #8,d1                                   * Shift a byte off the right
    lsr.l   #8,d1                                   * Shift a byte off the right
    rts
    
skip_bcc                                           * Skips data after a BCC so that we dont get ghost op code
    jsr     data                                   * Prints data to show that we ate some data
    jsr     get_displacement                       * Gets the displacement
    cmp.b   #$00,d1                                * If the opcode was expecting data after it
    beq     data                                   * Eat another word
    
compute_address_jump_table                         * Jump table to get to the various methods for computing EA
    jsr     compute_address_0
    rts
    jsr     compute_address_1
    rts
    jsr     compute_address_2
    rts
    jsr     compute_address_3
    rts
    jsr     compute_address_4
    rts
    jsr     compute_address_5
    rts
    jsr     compute_address_6
    rts
    jsr     compute_address_7
    rts
    jsr     compute_address_8
    rts
    
*-----------------------------------------------------------
*                   Address Mode Jump Table				 			       
*-----------------------------------------------------------
address_mode_jump_table                         * Jump table for going to different addressing modes
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
hex_jump_table                              * Jump table to make printing stuff easy
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
    rts
    
    
compute_address_0                           * Computes the address for things like move
    jsr     cut_opcode                      * Cuts off the opcode
    jsr     get_source                      * Prints the source
    move.b  #',',(a0)+                      
    jsr     get_destination                 * Prints the destination
    rts
    
compute_address_1                           * Computes the ea for stuff that only has a source
    jsr     cut_opcode                      * Cuts the opcode
    jsr     get_source                      * Prints the source
    rts

compute_address_2                           * Computes the opcode for things like BRA and Bcc
    jsr     cut_opcode                      * Cuts the opcode
    jsr     get_displacement                * Gets the displacement bits
    cmp.b   #$00,d1                         * Checks if we need another word
    beq     displacement_word               * If we do, get another word
    bne     displacement_byte               * Otherwise get a byte
    rts
    
compute_address_3                           * Computes the EA for stuff that only has immediate data as its source
    move.b  #%111,d1                        * Load the source mode and register bits for immediate data
    move.b  #%100,d3
    lea     address_mode_jump_table,a5      
    mulu    #8,d1
    jsr     (a5,d1)                         * Force it to jump to the immediate data portion of the jump table
    move.b  #',',(a0)+
    jsr     get_source                      * Gets the source as the destionation in this case
    rts
    
compute_address_4                           * Computes the address for things like lsl/asl
    jsr     cut_opcode                      * Cuts off the op code
    jsr     get_source_mode_bits            * Gets the source mode bits
    lsr     #2,d1                           * Shifts off bits to get the mode bit
    cmp.b   #1,d1
    beq     alt_compute_address_4           * If its mode 1, go to alternate
    move.b  #'#',(a0)+
    jsr     get_destination_register_bits   * Get the destination register bits (These are the rotation bits)
    cmp.b   #0,d1                           * Compare them to 0 (0 is 8)
    beq     shift_zero_to_eight_helper      * If its zero, go get some help from elsewhere
    jsr     finish_compute_address_4        * Finsih up somewhere else
    rts
    
alt_compute_address_4                       * If the mode is 1
    jsr     get_destination_register_bits   * Get the destination register number
    move.b  d1,d3                       
    move.b  #0,d1
    lea     address_mode_jump_table,a5
    jsr     (a5,d1)                         * Force it to go into the data register portion of the jump table
    jsr     finish_compute_address_4_alt    * Finish somewhere else    
    rts
    
shift_zero_to_eight_helper                  * What happens if the rotation is 000
    move.b  #$8,d1                          * Put 8 in there instead
 
finish_compute_address_4                    * Finishes up computing the address
    mulu    #8,d1                           * Gets the number to print for mode 0
    lea     hex_jump_table,a5
    jsr     (a5,d1)
finish_compute_address_4_alt
    move.b  #',',(a0)+                      
    jsr     get_source_register_bits        * Getting the source, which is the register we are shifting
    move.b  d1,d3
    move.b  #0,d1
    lea     address_mode_jump_table,a5
    jsr     (a5,d1)                         * Force it to go to the data register portion of the jump table
    rts
    
compute_address_5                           * Computing the address for something where the destination has to be a data reg
    jsr     cut_opcode                      * Cuts the opcode off
    jsr     get_source                      * Prints the source
    jsr     get_destination_register_bits   * Gets the data register number
    move.b  #',',(a0)+                          
    move.b  d1,d3                           
    move.b  #0,d1
    lea     address_mode_jump_table,a5      * Forces it to go to the data resgister section of the addressing jump table
    jsr     (a5,d1)
    rts

compute_address_6                           * Computes the opcode for stuff with directional bits
    jsr     cut_opcode                      * Cuts off the opcode
    jsr     get_direction_bit               * Get the directional bit
    cmp.b   #%1,d1                          * Check if its one
    beq     reg_to_mem_compute_6            * If its one, go to reg to mem
    cmp.b   #%0,d1                          * If its 0
    beq     mem_to_reg_compute_6            * Go from mem to reg
    rts
    
reg_to_mem_compute_6                        * Computes the EA if the directional bit is 1
    jsr     get_destination_register_bits   * Gets the dest register
    move.b  d1,d3                       
    lea     address_mode_jump_table,a5      * Forces it into the data register addressing mode
    move.b  #0,d1   
    jsr     (a5,d1)
    move.b  #',',(a0)+
    jsr     get_source                      * Prints the source    
    rts
    
mem_to_reg_compute_6                        * Computes the EA if the directional bit is 0
    jsr     get_source                      * Gets the source
    move.b  #',',(a0)+          
    jsr     get_destination_register_bits   * Gets the destination register
    move.b  d1,d3   
    move.b  #0,d1
    lea     address_mode_jump_table,a5      * Forces it into data register addressing mode
    jsr     (a5,d1)
    rts
    
compute_address_7                           * Computes the EA for something that requires an address register as its destination
    jsr     cut_opcode                      * Cuts off the opcode
    jsr     get_source                      * Prints the source
    move.b  #',',(a0)+              
    jsr     get_destination_register_bits   * Gets the destionation register bits
    move.b  d1,d3
    move.b  #%1,d1                         
    lea     address_mode_jump_table,a5      * Forces the jump table to go to address mode
    move.b  #8,d1
    jsr     (a5,d1)
    rts
    
compute_address_8                           * Computes the address for BCLR
    jsr     get_destination_register_bits   * Gets the destination register
    move.b  d1,d3
    move.b  #0,d1
    lea     address_mode_jump_table,a5      * Forces the jump table to go to a data register
    jsr     (a5,d1)                         
    move.b  #',',(a0)+
    jsr     get_source                      * Prints the source
    rts
    
*-----------------------------------------------------------
*                     Addressing Modes				 				
*-----------------------------------------------------------
* Printing the various different addressing modes to memory. Often, the register # is stored
* in d3 so that it can be printed with the addressing mode. Mode bits in d1, register bits d3 
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
    cmp.b   #%000,d3                * Checks if immediate data is actually short
    beq     absolute_word   
    cmp.b   #%001,d3                * Checks if immediate data is actually long
    beq     absolute_long
    
    move.b  #'#',(a0)+
    move.b  #'$',(a0)+
    
    cmp.b   #1,d6
    beq     immediate_byte
    cmp.b   #2,d6
    beq     immediate_word
    cmp.b   #3,d6
    beq     immediate_long
    
    rts
    
    
garbage1
    rts
    
garbage
    rts
    
absolute_word                       * Method to get the next word in mem when the opcode requires a short
    move.b  #'$',(a0)+
    bra     immediate_word
    rts

absolute_long
    move.b  #'$',(a0)+
    bra     immediate_long
    rts    
    
    
immediate_byte                      * Gets an immediate byte from memory
    move.w  (a2)+,d1                * Pulls the next word out of memory
immediate_byte_disp                 
    move.w  d1,d4                   * Moves a copy of it into a data register
    lsl.w   #5,d4                   * Shifts a nibble + 1 off the left
    lsl.w   #3,d4                   * Shifts a nibble -1 off the right
    lsr.w   #3,d4                   * Shifts a nibble -1 off the right
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lsr.w   #3,d4                   * Shifts a nibble - 1 from the right    
    lea     hex_jump_table,a5       * Gets the hex value from the jump table
    mulu    #8,d4
    jsr     (a5,d4)
    move.w  d1,d4
    lsl.w   #6,d4                   * Shifts a nibble and a half off the left                 
    lsl.w   #6,d4                   * Shifts a nibble and a half off the left
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    mulu    #8,d4                   * Gets the hex value from the jump table
    jsr     (a5,d4)
    rts
    
immediate_word
    move.w  (a2)+,d1                * Get the next word from mem
    move.w  d1,d4                   * Move a copy into a data reg
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lea     hex_jump_table,a5       * Gets the hex value from the jump table
    mulu    #8,d4      
    jsr     (a5,d4)
    move.w  d1,d4
    lsl.w   #4,d4                   * Shifts a nibble off the left
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    mulu    #8,d4                   * Gets the hex value from the jump table
    jsr     (a5,d4)
    move.w  d1,d4  
    lsl.w   #8,d4                   * Shifts a byte off the left
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    mulu    #8,d4                   * Get the hex value 
    jsr     (a5,d4)
    move.w  d1,d4
    lsl.w   #7,d4                   * Shift a byte - 1 off the left
    lsl.w   #5,d4                   * Shift a nibble + 1 off the left
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    lsr.w   #6,d4                   * Shifts a nibble and a half off the right
    mulu    #8,d4                   * Get the hex value from the hex jump table
    jsr     (a5,d4)
    rts
    
immediate_long                      * Gets a long from mem by just getting two words
    jsr     immediate_word
    jsr     immediate_word
    rts
    
displacement_word                   * If the displacement is a word, get an immediate short from the jump table
    move.b  #%111,d1
    move.b  #%000,d3                * Force the jump table to give you an immediate short
    lea     address_mode_jump_table,a5
    mulu    #8,d1
    jsr     (a5,d1)
    rts
    
displacement_byte                  * If the displacement is a byte, get the next byte using the immediate_byte method
    jsr     get_displacement
    jsr     immediate_byte_disp
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
empty   dc.b    ''                                                                           ,0
nx_pge  dc.b    'Press ENTER to proceed to the next page...'                                 ,0
reqf    dc.b    'Would you like to load opcodes from a text file'                            ,cr,lf
        dc.b    'starting at the specified starting address?(y/n)'                           ,0
warnf   dc.b    'WARNING: Reading from a file can potentially cause the'                     ,cr,lf
        dc.b    'program to malfunction if data existed in the specified'                    ,cr,lf
        dc.b    'address range. Please read the readme(FileIO) for '                         ,cr,lf
        dc.b    'information regarding how to format your file. Do you '                     ,cr,lf
        dc.b    'still want to proceed with file reading?(y/n)'                              ,0
    end    start















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
