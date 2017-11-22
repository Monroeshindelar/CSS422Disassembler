*-----------------------------------------------------------
* Title      : Disassembler
* Written by : JJ Abides, Dan Florsecu, Monroe Shindelar
* Date       : November 9th 2017 
* Description: 
*-----------------------------------------------------------
CR  EQU     $0D
LF  EQU     $0A

START       ORG $1000

*------------------------------
* Displaying Startup Message
*------------------------------
    LEA     SNP,A1
    MOVE.B  #14,D0
    TRAP    #15



SNP     DC.B    '                _ _                    _                                   ',CR,LF
        DC.B    '               | | |                  | |                                  ',CR,LF
        DC.B    '      ___  __ _| | |_   __ _ _ __   __| | _ __   ___ _ __  _ __   ___ _ __ ',CR,LF
        DC.B    '     / __|/ _` | | __| / _` | `_ \ / _` || `_ \ / _ \ `_ \| `_ \ / _ \ `__|',CR,LF
        DC.B    '     \__ \ (_| | | |_ | (_| | | | | (_| || |_) |  __/ |_) | |_) |  __/ |   ',CR,LF
        DC.B    '     |___/\__,_|_|\__| \__,_|_| |_|\__,_|| .__/ \___| .__/| .__/ \___|_|   ',CR,LF
        DC.B    '                                         | |        | |   | |              ',CR,LF
        DC.B    '                                         |_|        |_|   |_|              ',CR,LF,0
         

    END    START
