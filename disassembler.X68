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
*				     Effective Addressing					
*-----------------------------------------------------------
	move.w	test,d0
	
	lsl.w   #4,d0
	lsr.w   #4,d0
	bra     construct_effective_addresses
	
	bra     done
    
construct_effective_addresses
    jsr     get_source_mode_bits
    lea     address_mode_jump_table,a5
    lea     register_label_jump_table,a6
    mulu    #8,d1
    jsr     (a5,d1)
    jsr     get_source_register_bits
    mulu    #8,d1
    jsr     (a6,d1)
    move.b  #',',(a2)+
    jsr     get_destination_mode_bits
    mulu    #8,d1
    jsr     (a5,d1)
    jsr     get_destination_register_bits
    mulu    #8,d1
    jsr     (a6,d1) 

    rts


    

*-----------------------------------------------------------
*				   Get Destination Register					
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
*				      Get Source Mode				
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

done
    stop    #exit


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
*                    Register Label Jump Table			 				
*-----------------------------------------------------------
register_label_jump_table
    jsr     register_0
    rts
    jsr     register_1
    rts
    jsr     register_2
    rts     
    jsr     register_3
    rts
    jsr     register_4
    rts
    jsr     register_5
    rts
    jsr     register_6
    rts 
    jsr     register_7
    

data_register
    move.b  #'D',(a2)+
    rts
    
address_register
    move.b  #'A',(a2)+
    rts
    
address_mode_indirect
    rts
    
address_post_increment
    rts
    
address_post_decrement
    rts
    
immediate_data
    rts
    
garbage1
    rts
    
garbage
    rts
    
register_0
    move.b  #'0',(a2)+ 
    rts
    
register_1
    move.b  #'1',(a2)+
    rts
    
register_2
    move.b  #'2',(a2)+
    rts

register_3
    move.b  #'3',(a2)+
    rts

register_4
    move.b  #'4',(a2)+
    rts
    
register_5
    move.b  #'5',(a2)+
    rts
   
register_6
    move.b  #'6',(a2)+
    rts
    
register_7
    move.b  #'7',(a2)+
    rts
    
   
test	dc.w	$1003	
SNP     dc.b    '                _ _                    _                                   ',cr,lf
        dc.b    '               | | |                  | |                                  ',cr,lf
        dc.b    '      ___  __ _| | |_   __ _ _ __   __| | _ __   ___ _ __  _ __   ___ _ __ ',cr,lf
        dc.b    '     / __|/ _` | | __| / _` | `_ \ / _` || `_ \ / _ \ `_ \| `_ \ / _ \ `__|',cr,lf
        dc.b    '     \__ \ (_| | | |_ | (_| | | | | (_| || |_) |  __/ |_) | |_) |  __/ |   ',cr,lf
        dc.b    '     |___/\__,_|_|\__| \__,_|_| |_|\__,_|| .__/ \___| .__/| .__/ \___|_|   ',cr,lf
        dc.b    '                                         | |        | |   | |              ',cr,lf
        dc.b    '                                         |_|        |_|   |_|              ',cr,lf,0
         

    end    start

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
