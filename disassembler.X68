*-----------------------------------------------------------
* Title      : Disassembler
* Written by : JJ Abides, Dan Florsecu, Monroe Shindelar
* Date       : November 9th 2017 
* Description: 
*-----------------------------------------------------------
CR  EQU     $0D
LF  EQU     $0A

START       ORG $1000

*-----------------------------------------------------------
*				Displaying Startup Message
*-----------------------------------------------------------
    LEA     SNP,A1
    MOVE.B  #14,D0
    TRAP    #15
	
*-----------------------------------------------------------
*				   Effective Addressing					
*-----------------------------------------------------------
	move.w	test,d0
	lsl.w   #4,d0
	lsr.w   #4,d0
	jsr     isolate_source_register

    bra     done


*-----------------------------------------------------------
*				  Get Destination Register					
*-----------------------------------------------------------	
get_destination_register
    move.w  d0,d1
    lsr.w   #8,d1
    lsr.b   #1,d1
    rts

*-----------------------------------------------------------
*				    Get Destination Mode				
*-----------------------------------------------------------    
get_destination_mode
    move.w  d0,d1
    lsl.w   #7,d1
    lsr.w   #8,d1
    lsr.w   #5,d1
    rts

*-----------------------------------------------------------
*				      Get Source Mode				
*-----------------------------------------------------------
get_source_mode
    move.w  d0,d1
    lsl.w   #6,d1
    lsl.w   #4,d1
    lsr.w   #8,d1
    lsr.w   #5,d1
    rts
    
    
*-----------------------------------------------------------
*                    Get Source Register				 				
*-----------------------------------------------------------    
get_source_register
    move.w  d0,d1
    lsl.w   #8,d1
    lsl.w   #5,d1
    lsr.w   #8,d1
    lsr.b   #5,d1
    rts


done


*-----------------------------------------------------------
*              Determine Address Mode Jump Table				 				
*-----------------------------------------------------------
determine_address_mode
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
    
    
data_register
    rts
    
address_register
    rts
    
address_mode_indirect
    rts
    
address_post_increment
    rts
    
address_post_decrement
    rts
    
immediate_data
    rts 



test	dc.w	$8A5B	
SNP     DC.B    '                _ _                    _                                   ',CR,LF
        DC.B    '               | | |                  | |                                  ',CR,LF
        DC.B    '      ___  __ _| | |_   __ _ _ __   __| | _ __   ___ _ __  _ __   ___ _ __ ',CR,LF
        DC.B    '     / __|/ _` | | __| / _` | `_ \ / _` || `_ \ / _ \ `_ \| `_ \ / _ \ `__|',CR,LF
        DC.B    '     \__ \ (_| | | |_ | (_| | | | | (_| || |_) |  __/ |_) | |_) |  __/ |   ',CR,LF
        DC.B    '     |___/\__,_|_|\__| \__,_|_| |_|\__,_|| .__/ \___| .__/| .__/ \___|_|   ',CR,LF
        DC.B    '                                         | |        | |   | |              ',CR,LF
        DC.B    '                                         |_|        |_|   |_|              ',CR,LF,0
         

    END    START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
