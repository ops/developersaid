;***********************************************************************************;
;***********************************************************************************;
;
; Developers' Aid for VIC-20
; Hacked together by ops 2019

; Based on Programmers' Aid cartridge and
; The almost completely commented Programmers' Aid ROM disassembly. v1.0
; By Simon Rowe <srowe@mose.org.uk>.

; C'mon - Machine Code Monitor for Commodore VIC-20 - v1.0
; (c)2001 Aleksi Eeben (email: aeeben@paju.oulu.fi)

; over5 - a c64/vic20 remote access solution.
; Copyright (c) 1995, 1996, 2000, 2002 Daniel Kahlin <daniel@kahlin.net>
; All rights reserved.

;***********************************************************************************;
;***********************************************************************************;
;
#include "version.inc"

; BASIC zero page

LISTQUO = $0f                   ; list in quote mod.
LINNUM  = $14                   ; temporary integer
INDEX   = $22                   ; misc temp byte
TXTTAB  = $2B                   ; start of memory
VARTAB  = $2D                   ; start of variables
ARYTAB  = $2F                   ; end of variables
CURLIN  = $39                   ; current line number
MEMSIZ  = $37                   ; end of memory
VARNAM  = $45                   ; current variable name
VARPNT  = $47                   ; current variable address
TMPPTR  = $5F                   ; temporary pointer
CHRGET  = $73                   ; increment and scan memory, BASIC byte get
CHRGOT  = $79                   ; scan memory, BASIC byte get

; KERNAL zero page

STATUS  = $90                   ; st
VERCK   = $93                   ; load/verify flag
DEVNUM  = $BA                   ; current device number
FNADR   = $BB                   ; file name pointer
LSTX    = $C5                   ; last key pressed
NDX     = $C6                   ; keyboard buffer length/index
RVS     = $C7                   ; reverse flag
SFDX    = $CB                   ; which key
BLNSW   = $CC                   ; cursor enable
CDBLN   = $CE                   ; character under cursor
BLNON   = $CF                   ; cursor blink phase
PNT     = $D1                   ; current screen line pointer
PNTR    = $D3                   ; cursor column
QTSW    = $D4                   ; cursor quote flag
LNMX    = $D5                   ; current screen line length
TBLX    = $D6                   ; cursor row
INSRT   = $D8                   ; insert count
LDTB1   = $D9                   ; screen line link table
USER    = $F3                   ; colour RAM pointer

STACK   = $0100                 ; bottom of the stack page

BUF     = $0200                 ; input buffer
KEYD    = $0277                 ; keyboard buffer
MEMHIGH = $0283                 ; OS top of memory low byte
COLOR   = $0286                 ; current colour code
GDCOL   = $0287                 ; colour under cursor
HIBASE  = $0288                 ; screen memory page
SHFLAG  = $028D                 ; keyboard shift/control flag
KEYLOG  = $028F                 ; keyboard decode logic pointer
AUTODN  = $0292                 ; screen scrolling flag, $00 = enabled

TBUFFR  = $033C                 ; to $03FB - cassette buffer

; VIA registers
VIA1PA1 = $9111                 ; VIA 1 DRA

; BASIC entrypoints
WARMST  = $C002                 ; BASIC warm start entry point
RESLST  = $C09E                 ; BASIC keywords
MEMERR  = $C435                 ; do out of memory error then warm start
READY   = $C474                 ; do warm start
LNKPRG  = $C533                 ; rebuild BASIC line chaining
CRNCH   = $C579                 ; crunch BASIC token vector
CRNCH2  = $C57C                 ; crunch BASIC token
FINLIN  = $C613                 ; search BASIC for temporary integer line number
CLR     = $C659                 ; perform clr
DECBIN  = $C96B                 ; get fixed-point number into temporary integer
PRCRLF  = $CAD7                 ; print CR/LF
FRMEVL  = $CD9E                 ; evaluate expression
PRTSTR  = $CB1E                 ; print null terminated string
COMCHK  = $CEFD                 ; scan for ","
RETVP   = $D185                 ; return variable
ILQUAN  = $D248                 ; do illegal quantity error
MAKFP   = $D391                 ; convert fixed integer .A.Y to float FAC1
DELST   = $D6A3                 ; evaluate string
LODFAC  = $DBA2                 ; unpack memory (.A.Y) into FAC1
PRTFIX  = $DDCD                 ; print .X.A as unsigned integer
FLTASC  = $DDDD                 ; convert FAC1 to ASCII string result in (.A.Y)
PARSL   = $E1D1                 ; get parameters for LOAD/SAVE
CGIMAG  = $E387                 ; character get subroutine for zero page
INITBA  = $E3A4

; KERNAL entrypoints
INITVCTRS = $E45B
FREMSG  = $E404
INITSK  = $E518                 ; initialize hardware
HOME    = $E581                 ; home cursor
MOVLIN  = $EA56                 ; shift screen line up/down
LINPTR  = $EA7E                 ; set start of line .X
CLRALINE = $EA8D                ; clear screen line .X
COLORSYN = $EAB2                ; calculate pointer to colour RAM
SETKEYS = $EBDC                 ; evaluate SHIFT/CTRL/C= keys
LDTB2   = $EDFD                 ; low byte screen line addresses
FUDTIM  = $F734                 ; increment real time clock
FRESTOR = $FD52                 ; restore default I/O vectors
INITMEM = $fd8d                 ; initialise and test RAM
INITVIA = $FDF9                 ; initialize I/O registers
_RTI    = $FF56                 ; restore registers and exit interrupt
SECOND  = $FF93
TKSA    = $FF96
ACPTR   = $FFA5
CIOUT   = $FFA8
UNTLK   = $FFAB
UNLSN   = $FFAE
LISTEN  = $FFB1
TALK    = $FFB4
SETLFS  = $FFBA
OPEN    = $FFC0
CLOSE   = $FFC3
CHKIN   = $FFC6
CLRCHN  = $FFCC
CHRIN   = $FFCF
CHROUT  = $FFD2                 ; output character to channel (via vector)
LOAD    = $FFD5                 ; load RAM from a device (via vector)
STOP    = $FFE1                 ; scan the stop key


;***********************************************************************************;
;
; BASIC keyword token values

TK_TO           = $A4           ; TO token
TK_MINUS        = $AB           ; - token
TK_GO           = $CB           ; GO token
TK_PI           = $FF           ; PI token

KEYTBLSZ = 120                  ; 12 keys * 10 bytes

MODE    = $7F                   ; command mode, $01 = AUTO, $02 = TRACE, $03 = STEP
AUTONXT = $83                   ; AUTO next line number
RENNXT  = $85                   ; RENUMBER next line number

CHNGFLG = $02CC                 ; find/change flag, $00 = FIND, $01 = CHANGE
AUTOINC = $03E2                 ; AUTO increment
TRACELN = $03E4                 ; to $03F1 - TRACE/STEP line numbers


;***********************************************************************************;
;***********************************************************************************;
;
; Programmers' Aid ROM start

        * = $a000

        .WORD dainit
        .WORD PANMI
        .BYT "A0",$C3,$C2,$CD   ; A0CBM


;***********************************************************************************;
;
; NMI handler

PANMI
        BIT VIA1PA1             ; test VIA 1 DRA, clear CA1 interrupt
        JSR FUDTIM              ; increment real time clock
        JSR STOP                ; scan the stop key
        BEQ L7053               ; branch if [STOP]

        JMP _RTI                ; restore registers and exit interrupt

L7053   JSR FRESTOR             ; restore default I/O vectors
        JSR INITVIA             ; initialize I/O registers
        JSR INITSK              ; initialize hardware
        LDA #$00                ; clear .A
        STA $02CA
        JSR INITKEYLOG
        JMP (WARMST)            ; BASIC warm start entry point

;***********************************************************************************;
;
; initialize keyboard decode handler vector

INITKEYLOG
        LDA #<KEYBDEC           ; keyboard decode handler low byte
        STA KEYLOG              ; set keyboard decode logic pointer low byte
        LDA #>KEYBDEC           ; keyboard decode handler high byte
        STA KEYLOG+1            ; set keyboard decode logic pointer high byte
        RTS


;***********************************************************************************;
;
; initialize variables

INITVAR
        LDA #10
        STA AUTOINC             ; set AUTO increment low byte
        LDA #$00
        STA AUTOINC+1           ; set AUTO increment high byte
        STA RENNXT+1            ; set RENUMBER next line number high byte
        STA MODE                ; clear command mode
        STA AUTONXT+1           ; clear AUTO next line number high byte
        LDA #100
        STA RENNXT              ; set RENUMBER next line number low byte
        STA AUTONXT             ; set AUTO next line number low byte
        RTS


;***********************************************************************************;
;
; parse parameters for AUTO/RENUMBER

PARSEAR
        JSR CHRGET              ; increment and scan memory
        BEQ L70D7               ; exit if no more chrs

        BCS L70BE               ; if not numeric do syntax error then warm start

        JSR DECBIN              ; get fixed-point number into temporary integer
        PHA                     ; save next character in command
        LDA LINNUM+1            ; get start line number high byte
        LDX LINNUM              ; get start line number low byte
        STA RENNXT+1            ; set RENUMBER next line number high byte
        STX RENNXT              ; set RENUMBER next line number low byte
        STA AUTONXT+1           ; set AUTO next line number high byte
        STX AUTONXT             ; set AUTO next line number low byte
        PLA                     ; restore next character in command
        BEQ L70D7               ; exit if no more chrs

        CMP #','                ; compare with ","
        BEQ L70C1               ; if "," then parse interval

L70BE   JMP $CF08               ; otherwise do syntax error then warm start

L70C1   JSR CHRGET              ; increment and scan memory
        BCS L70BE               ; if not numeric do syntax error then warm start

        JSR DECBIN              ; get fixed-point number into temporary integer
        PHA                     ; save next character in command
        LDA LINNUM+1            ; get interval high byte
        LDX LINNUM              ; get interval low byte
        STA AUTOINC+1           ; set AUTO increment high byte
        STX AUTOINC             ; set AUTO increment low byte
        PLA                     ; restore next character in command
        BNE L70BE               ; if more chrs do syntax error then warm start

L70D7   RTS


;***********************************************************************************;
;
; add increment to AUTO next line number

ADDINC
        CLC
        LDA AUTONXT             ; get AUTO next line number low byte
        ADC AUTOINC             ; add AUTO increment low byte
        STA AUTONXT             ; set AUTO next line number low byte
        LDA AUTONXT+1           ; get AUTO next line number high byte
        ADC AUTOINC+1           ; add AUTO increment high byte
        STA AUTONXT+1           ; set AUTO next line number high byte
        BCS L70EB               ; branch if > 65535 ($FFFF)

        CMP #$FA                ; compare with 64000 ($FA00)
L70EB   RTS


;***********************************************************************************;
;
; perform RENUMBER

L70EC   JSR INITVAR             ; initialize variables
        JSR PARSEAR             ; parse parameters for AUTO/RENUMBER
        JSR CPYWORD             ; copy word in zero page
        .BYT TXTTAB,TMPPTR      ; copy start of memory to temporary pointer
L70F7   JSR READPTR             ; read through temporary pointer
        BNE L70FF

        JMP L7134

L70FF   JSR ADDINC              ; add increment to AUTO next line number
        BCC L70F7               ; branch if < 64000

        JMP RANGERR             ; do out of range error then warm start


;***********************************************************************************;
;
; set immediate mode and do BASIC warm start

DOREADY
        LDA #$FF                ; current line high byte to -1, indicates immediate mode
        STA CURLIN+1            ; set current line number high byte
        JMP READY               ; do warm start


;***********************************************************************************;
;
;

L710E   LDA RENNXT              ; get RENUMBER next line number low byte
        STA AUTONXT             ; set AUTO next line number low byte
        LDA RENNXT+1            ; get RENUMBER next line number high byte
        STA AUTONXT+1           ; set AUTO next line number high byte
        JSR CPYWORD             ; copy word in zero page
        .BYT TXTTAB,TMPPTR      ; copy start of memory to temporary pointer
L711B   LDY #$03
        LDA AUTONXT+1           ; get AUTO next line number high byte
        STA (TMPPTR),Y
        DEY
        LDA AUTONXT             ; set AUTO next line number high byte
        STA (TMPPTR),Y
        JSR ADDINC              ; add increment to AUTO next line number
        JSR READPTR             ; read through temporary pointer
        BNE L711B

        JSR $C659               ; reset execute pointer and do CLR
        JMP DOREADY             ; set immediate mode and do BASIC warm start


;***********************************************************************************;
;
;

L7134   JSR STOSTRT             ; store address of start of memory in temporary pointer
L7137   JSR READPTR             ; read through temporary pointer
        BEQ L710E

        LDY #$04
        STY $0F
L7140   LDA (TMPPTR),Y
L7142   BEQ L7137

        CMP #$22                ; compare with "
        BNE L7150

        LDA $0F
        EOR #$FF
        STA $0F
        BNE L7162

L7150   BIT $0F
        BMI L7162

        CMP #$8F
        BEQ L7137

        LDX #$06
L715A   CMP L72B4-1,X
        BEQ L7174

        DEX
        BNE L715A

L7162   INY
        BNE L7140


;***********************************************************************************;
;
; read through temporary pointer
;
; Read from the address pointed to by TMPPTR, plus 1, return byte in .A

READPTR
        LDY #$00                ; clear index
        LDA (TMPPTR),Y          ; get address low byte
        TAX                     ; copy to .X
        INY                     ; increment index
        LDA (TMPPTR),Y          ; get address high byte
        STX TMPPTR              ; set address low byte
        STA TMPPTR+1            ; set address high byte
        LDA (TMPPTR),Y          ; get data byte from (TMPPTR+1)
        RTS


;***********************************************************************************;
;
;

L7174   CLC
        TYA
        ADC TMPPTR
        STA CHRGOT+1            ; save BASIC execute pointer low byte
        STA $5A
        LDX TMPPTR+1
        BCC L7181

        INX
L7181   STX CHRGOT+2            ; save BASIC execute pointer high byte
        STX $5B
        JSR CHRGET              ; increment and scan memory
        BCC L7194               ; branch if numeric character

        CMP #TK_MINUS           ; compare with token for "-"
        BEQ L71C4

        CMP #TK_TO              ; compare with token for "TO"
        BNE L7162

        BEQ L71C4               ; branch always

L7194   JSR DECBIN              ; get fixed-point number into temporary integer
        JSR L71DC
        JSR CPYWORD             ; copy word in zero page
        .BYT $5A,CHRGOT+1
        LDX #$00
        LDY #$00
L71A3   LDA STACK+1,X
        BEQ L71B7

        PHA
        JSR CHRGET              ; increment and scan memory
        BCC L71B1               ; branch if numeric

        JSR L7223
L71B1   PLA
        STA (CHRGOT+1),Y        ; set BASIC byte
        INX
        BNE L71A3

L71B7   JSR CHRGET              ; increment and scan memory
L71BA   JSR CHRGOT              ; scan memory
        BCS L71C4               ; branch if not numeric character

        JSR L728D
        BEQ L71BA

L71C4   TAX
        SEC
        LDA CHRGOT+1            ; get BASIC execute pointer low byte
        SBC TMPPTR
        TAY
        TXA
        CMP #','                ; compare with ","
        BEQ L7174

        CMP #TK_MINUS           ; compare with token for "-"
        BEQ L7174

        CMP #TK_TO              ; compare with token for "TO"
        BEQ L7174

        TAX
        JMP L7142


;***********************************************************************************;
;
;

L71DC   LDA RENNXT              ; get RENUMBER next line number low byte
        LDX RENNXT+1            ; get RENUMBER next line number high byte
        STA AUTONXT             ; set AUTO next line number low byte
        STX AUTONXT+1           ; set AUTO next line number high byte
        JSR CPYWORD             ; copy word in zero page
        .BYT TXTTAB,$24
L71E9   LDY #$03
        LDA ($24),Y
        CMP LINNUM+1
        BNE L7209

        DEY
        LDA ($24),Y
        CMP LINNUM
        BNE L7209


;***********************************************************************************;
;
;

L71F8   LDA AUTONXT+1           ; get AUTO next line number high byte
        LDX AUTONXT             ; get AUTO next line number low byte

L71FC   STA $62
        STX $63
        LDX #$90                ; set exponent to 16d bits
        SEC                     ; set integer is +ve flag
        JSR $DC49               ; set exponent = .X, clear mantissa 4 and 3 and normalise FAC1
        JMP FLTASC              ; convert FAC1 to ASCII string result in (.A.Y)

L7209   JSR ADDINC              ; add increment to AUTO next line number
        LDY #$01
        LDA ($24),Y
        BNE L7218

        LDA #>$FA00-1
        LDX #<$FA00-1
        BNE L71FC               ; branch always

L7218   TAX
        DEY                     ; clear .Y
        LDA ($24),Y
        STX $25
        STA $24
        JMP L71E9


;***********************************************************************************;
;
;

L7223   STX $8A                 ; save .X
        LDX VARTAB              ; get start of variables low byte
        LDY VARTAB+1            ; get start of variables high byte
        STX $58
        STY $59
        INX
        BNE L7231

        INY
L7231   CPX MEMSIZ              ; compare with end of memory low byte
        TYA
        SBC $38
        BCC L723B

        JMP MEMERR              ; do out of memory error then warm start

L723B   STY VARTAB+1            ; set start of variables high byte
        STX VARTAB              ; set start of variables low byte
        LDY #$01
        LDX #$00
L7243   LDA ($58,X)
        STA ($58),Y
        LDA $58
        BNE L724D

        DEC $59
L724D   DEC $58
        LDA $58
        CMP CHRGOT+1            ; compare with BASIC execute pointer low byte
        LDA $59
        SBC CHRGOT+2            ; subtract save BASIC execute pointer high byte
        BCS L7243

L7259   PHP                     ; save flags
        JSR CPYWORD             ; copy word in zero page
        .BYT TMPPTR,$5A
        PLP                     ; restore flags
        LDY #$01
L7262   LDA ($5A),Y
        BNE L726A

        LDX $8A                 ; restore .X
        DEY
        RTS

L726A   TAX
        DEY
        LDA ($5A),Y
        TAY
        BCS L7277

        INY
        BNE L727B

        INX
        BNE L727B

L7277   BNE L727A

        DEX
L727A   DEY
L727B   TYA
        LDY #$00
        STA ($5A),Y
        PHA
        TXA
        INY
        STA ($5A),Y
        STA $5B
        PLA
        STA $5A
        JMP L7262


;***********************************************************************************;
;
;

L728D   LDA VARTAB              ; get start of variables low byte
        BNE L7293

        DEC VARTAB+1            ; decrement start of variables high byte
L7293   DEC VARTAB              ; decrement start of variables low byte
        JSR CPYWORD             ; copy word in zero page
        .BYT CHRGOT+1,$58
        LDY #$01
        LDX #$00
L729E   LDA ($58),Y
        STA ($58,X)
        INC $58
        BNE L72A8

        INC $59
L72A8   LDA $58
        CMP VARTAB              ; compare with start of variables low byte
        LDA $59
        SBC VARTAB+1            ; subtract start of variables high byte
        BCC L729E

        BCS L7259               ; branch always

L72B4   .BYT $9B,$8A,$A7,$89,$8D,$CB


;***********************************************************************************;
;
; do out of range error then warm start

RANGERR
        JSR INITVAR             ; initialize variables
        LDA #<RANGSTR           ; set "?OUT OF RANGE" pointer low byte
        LDY #>RANGSTR           ; set "?OUT OF RANGE" pointer high byte
        JSR PRTSTR              ; print null terminated string
        JMP $C462               ; print " ERROR" and do warm start

RANGSTR
        .BYT "?OUT OF RANGE",$00


;***********************************************************************************;
;
; copy a word stored are one zero page address to another.
; The source and destination are defined in the two bytes that follow the jump to
; this routine, e.g.
;
;     JSR CPYWORD
;     .BYT $11,$22
;
; copies the word at $11,$12 to $22,$23

CPYWORD
        CLC
        PLA                     ; pull return address low byte
        STA $87                 ; set parameter adress low byte
        ADC #$02                ; add two to skip parameters that follow the JSR
        TAX                     ; copy new return address low byte
        PLA                     ; pull return address high byte
        STA $88                 ; set parameter adress high byte
        ADC #$00                ; add carry
        PHA                     ; push back onto stack
        TXA                     ; restore return address low byte
        PHA                     ; push back onto stack
        LDY #$01                ; return address points to last byte of JSR
        LDA ($87),Y             ; get source zero page address
        TAX                     ; copy to .X
        INY                     ; increment index
        LDA ($87),Y             ; get destination zero page address
        TAY                     ; copy to .Y
        LDA $00,X               ; get low byte from source zero page address
        STA $0000,Y             ; set low byte of destination zero page address
        LDA $01,X               ; get high byte from source zero page address
        STA $0001,Y             ; set high byte of destination zero page address
        RTS


;***********************************************************************************;
;
; store address of start of memory in temporary pointer

STOSTRT
        LDA #TXTTAB             ; start of memory pointer low byte
        STA TMPPTR              ; set temporary pointer low byte
        LDX #$00                ; page zero
        STX TMPPTR+1            ; set temporary pointer high byte
        RTS


;***********************************************************************************;
;
; patch CHRGOT, display banner and initialize variables

DOPATCH
        LDX #$07                ; length of patch
L7303   LDA L7315-1,X           ; get patch code
        STA CHRGOT+2,X          ; store in CHRGOT routine
        DEX                     ; decrement index
        BNE L7303               ; loop until done

        LDA #<BANNER            ; get banner string address low byte
        LDY #>BANNER            ; get banner string address high byte
        JSR PRTSTR              ; print null terminated string
        JMP INITVAR             ; initialize variables

        ; patch to CHARGOT routine

L7315   JMP L731C               ; replacement character get subroutine

        .BYT $00                ; ?? dead code ??
        JMP L7344               ; ?? dead code ??


;***********************************************************************************;
;
; replacement character get subroutine

L731C   PHA                     ; save BASIC byte
        STX $8A
        LDA CHRGOT+2            ; get BASIC execute pointer high byte
        CMP #>BUF               ; compare with input buffer high byte
        BNE L732B               ; if not immediate mode ???

        LDA CHRGOT+1            ; get BASIC execute pointer low byte
        BEQ L734F               ; beginning of input buffer

        BNE L732F               ; branch always

L732B   LDA CHRGOT+1            ; get BASIC execute pointer low byte
        STA $89
L732F   LDA MODE                ; get command mode
        BEQ L733D               ; continue if no mode set

        CMP #$01                ; compare mode with AUTO
        BNE L733A               ; branch if not AUTO

        JMP L7815               ; ??? do AUTO ???

L733A   JMP L761E               ; ??? do TRACE/STEP ???

L733D   LDX $8A
        PLA                     ; restore BASIC byte
        CMP #':'                ; compare with ":"
        BCS L734E               ; exit if >=

L7344   CMP #' '                ; compare with " "
        BNE L734B               ; not [SPACE], clear Cb if numeric and retirn

        JMP CHRGET              ; increment and scan memory

L734B   JMP $E398               ; clear carry if byte = "0"-"9" and return

L734E   RTS

L734F   TSX                     ; copy stack pointer
        LDA STACK+3,X           ; get high byte of return address
        CMP #$C4                ; compare with $C4xx
        BNE L732F

        ; called from MAIN2

        LDY #$00                ; clear .Y
        STY $0B                 ; clear keyword index
L735B   LDX #$FF                ; set index to end of input buffer then ..
L735D   INX                     ; increment index
        LDA BUF,X               ; get a byte from the input buffer
        BMI L732F               ; ?? token ??

        CMP #' '                ; compare with " "
        BEQ L735D               ; repeat while [SPACE]

L7367   LDA KEYWDS,Y            ; get byte from keyword table
        BEQ L732F               ; end of keywords

        EOR BUF,X               ; XOR with byte in input buffer
        BNE L7375               ; not equal, check for end of keyword

        INY                     ; increment table index
        INX                     ; increment buffer index
        BPL L7367               ; repeat for next, branch always

L7375   CMP #$80                ; just b7 different
        BEQ L7383               ; keyword matches

L7379   INY                     ; increment table index
        LDA KEYWDS-1,Y          ; get byte from keyword table
        BPL L7379               ; repeat until end of keyword

        INC $0B                 ; increment keyword index
        BNE L735B               ; repeat for next keyword, branch always

L7383   INC CHRGOT+1            ; increment BASIC execute pointer low byte
        DEX                     ; decrement buffer index
        BNE L7383               ; repeat until pointer advanced to consume keyword

        LDX $0B                 ; get keyword index
        CPX #$02                ; compare with "STEP"
        BMI L7390

        PLA                     ; dump BASIC byte
        PLA                     ; dump return address low byte
L7390   PLA                     ; dump return address high byte
        LDA L73EE,X             ; get command high byte
        PHA                     ; push on to stack
        LDA L73FE,X             ; get command low byte
        PHA                     ; push on to stack
        SEI                     ; disable interrupts
        JSR INITKEYLOG
        CLI                     ; enable interrupts
        RTS                     ; invoke command


;***********************************************************************************;
;
; BASIC keywords. Each word has b7 set in its last character as an end marker.

KEYWDS
        .BYT "RU",'N'+$80       ; RUN
        .BYT "AUT",'O'+$80      ; AUTO
        .BYT "STE",'P'+$80      ; STEP
        .BYT "TRAC",'E'+$80     ; TRACE
        .BYT "OF",'F'+$80       ; OFF
        .BYT "RENUMBE",'R'+$80  ; RENUMBER
        .BYT "DELET",'E'+$80    ; DELETE
        .BYT "HEL",'P'+$80      ; HELP
        .BYT "FIN",'D'+$80      ; FIND
        .BYT "DUM",'P'+$80      ; DUMP
        .BYT "PRO",'G'+$80      ; PROG
        .BYT "EDI",'T'+$80      ; EDIT
        .BYT "CHANG",'E'+$80    ; CHANGE
        .BYT "KE",'Y'+$80       ; KEY
        .BYT "MERG",'E'+$80     ; MERGE
        .BYT "KIL",'L'+$80      ; KILL
        ; extensions
        .BYT "CMO",'N'+$80      ; CMON
        .BYT "OL",'D'+$80       ; OLD
        .BYT "O5SN",'D'+$80     ; O5SND
        .BYT "O5RC",'V'+$80     ; O5RCV
        .BYT "DIRECTOR",'Y'+$80 ; DIRECTORY
        .BYT "DISKCM",'D'+$80   ; DISKCMD
        .BYT "BASCA",'T'+$80    ; BASCAT
        .BYT $00


;***********************************************************************************;
;
; Action addresses for commands. These are called by pushing the address onto the
; stack and doing an RTS so the actual address - 1 needs to be pushed.

L73EE   .BYT >L740E-1           ; perform RUN (MSB)
        .BYT >L7808-1           ; perform AUTO (MSB)
        .BYT >L7617-1           ; perform STEP (MSB)
        .BYT >L7614-1           ; perform TRACE (MSB)
        .BYT >L7611-1           ; perform OFF (MSB)
        .BYT >L70EC-1           ; perform RENUMBER (MSB)
        .BYT >L76CF-1           ; perform DELETE (MSB)
        .BYT >L7780-1           ; perform HELP (MSB)
        .BYT >L742B-1           ; perform FIND (MSB)
        .BYT >L7861-1           ; perform DUMP (MSB)
        .BYT >L7BB1-1           ; perform PROG (MSB)
        .BYT >L7BBE-1           ; perform EDIT (MSB)
        .BYT >L7423-1           ; perform CHANGE (MSB)
        .BYT >L7943-1           ; perform KEY (MSB)
        .BYT >L7E0E-1           ; perform MERGE (MSB)
        .BYT >L7A31-1           ; perform KILL (MSB)
        ; extensions
        .BYT >PERFORM_CMON-1    ; perform CMON (MSB)
        .BYT >PERFORM_OLD-1     ; perform OLD (MSB)
        .BYT >PERFORM_O5SND-1   ; perform O5SND (MSB)
        .BYT >PERFORM_O5RCV-1   ; perform O5RCV (MSB)
        .BYT >PERFORM_DIRECTORY-1 ; perform DIRECTORY (MSB)
        .BYT >PERFORM_DISKCMD-1 ; perform DISKCMD (MSB)
        .BYT >PERFORM_BASCAT-1  ; perform BASCAT (MSB)

L73FE   .BYT <L740E-1           ; perform RUN (LSB)
        .BYT <L7808-1           ; perform AUTO (LSB)
        .BYT <L7617-1           ; perform STEP (LSB)
        .BYT <L7614-1           ; perform TRACE (LSB)
        .BYT <L7611-1           ; perform OFF (LSB)
        .BYT <L70EC-1           ; perform RENUMBER (LSB)
        .BYT <L76CF-1           ; perform DELETE (LSB)
        .BYT <L7780-1           ; perform HELP (LSB)
        .BYT <L742B-1           ; perform FIND (LSB)
        .BYT <L7861-1           ; perform DUMP (LSB)
        .BYT <L7BB1-1           ; perform PROG (LSB)
        .BYT <L7BBE-1           ; perform EDIT (LSB)
        .BYT <L7423-1           ; perform CHANGE (LSB)
        .BYT <L7943-1           ; perform KEY (LSB)
        .BYT <L7E0E-1           ; perform MERGE (LSB)
        .BYT <L7A31-1           ; perform KILL (LSB)
        ; extensions
        .BYT <PERFORM_CMON-1    ; perform CMON (LSB)
        .BYT <PERFORM_OLD-1     ; perform OLD (LSB)
        .BYT <PERFORM_O5SND-1   ; perform O5SND (LSB)
        .BYT <PERFORM_O5RCV-1   ; perform O5RCV (LSB)
        .BYT <PERFORM_DIRECTORY-1 ; perform DIRECTORY (LSB)
        .BYT <PERFORM_DISKCMD-1 ; perform DISKCMD (LSB)
        .BYT <PERFORM_BASCAT-1  ; perform BASCAT (LSB)


;***********************************************************************************;
;
; perform RUN

L740E   LDX #$0E                ; 7 line numbers
        LDA #$FF                ; inactive row indicator
L7412   STA TRACELN-1,X         ; set TRACE/STEP line number
        DEX                     ; decrement index
        BNE L7412               ; repeat for all lines

        LDX #$00                ; clear .X
        STX CHRGOT+1            ; clear BASIC execute pointer low byte
        PHA
        JMP L733D

        JMP DOREADY             ; ?? dead code ??


;***********************************************************************************;
;
; perform CHANGE

L7423   LDX #$01                ; CHANGE
        STX CHNGFLG             ; set find/change flag
        DEX                     ; clear .X
        BEQ L7430               ; branch always


;***********************************************************************************;
;
; perform FIND

L742B   LDX #$00                ; FIND
        STX CHNGFLG             ; set find/change flag
L7430   STX $03E0
        STX $02CD
        STX $02CE
        JSR CHRGET              ; increment and scan memory
        TAX                     ; copy byte to set flags
        BEQ L7457               ; branch if no more chrs

        CMP #','                ; compare with ","
        BEQ L7457

        CMP #$22                ; compare with "
        BEQ L7450

        JSR CRNCH               ; crunch BASIC token
        JSR CHRGET              ; increment and scan memory
        JMP L7460

L7450   DEC $03E0
        JSR CHRGET              ; increment and scan memory
        TAX                     ; copy byte to set flags
L7457   BEQ L74AF               ; if no more chrs do syntax error then warm start

        CMP #$22                ; compare with "
        BEQ L74AF               ; if " do syntax error then warm start

        DEC $02CD
L7460   LDA CHRGOT+1            ; get BASIC execute pointer low byte
        STA $0F
        LDA CHNGFLG             ; get find/change flag
        BEQ L74B2               ; branch if FIND

L7469   JSR CHRGET              ; increment and scan memory
        INC $02CD
        TAX                     ; copy byte to set flags
        BEQ L74AF               ; if no more chrs do syntax error then warm start

        CMP #','                ; compare with ","
        BNE L7469

        JSR CHRGET              ; increment and scan memory
        TAX                     ; copy byte to set flags
        BEQ L74BF               ; branch if no more chrs

        CMP #','                ; compare with ","
        BEQ L74A9

        CMP #$22                ; compare with "
        BNE L7492

        LDA $03E0
        BEQ L74AF               ; do syntax error then warm start

        DEC $02CE
        JSR CHRGET              ; increment and scan memory
        JMP L7497

L7492   LDA $03E0
        BNE L74AF               ; do syntax error then warm start

L7497   LDA CHRGOT+1            ; get BASIC execute pointer low byte
        STA $02CF
L749C   JSR CHRGET              ; increment and scan memory
        INC $02CE
        TAX                     ; copy byte to set flags
        BEQ L74BF               ; branch if no more chrs

        CMP #','                ; compare with ","
        BNE L749C

L74A9   JSR CHRGET              ; increment and scan memory
        JMP L74BF

L74AF   JMP $CF08               ; do syntax error then warm start

L74B2   JSR CHRGET              ; increment and scan memory
        TAX                     ; copy byte to set flags
        BEQ L74BF               ; branch if no more chrs

        CMP #','                ; compare with ","
        BNE L74B2

        JSR CHRGET              ; increment and scan memory
L74BF   JSR LNRANGE             ; parse FROM - TO line number range
        TAX                     ; update flags
        BNE L74AF               ; do syntax error then warm start

        JSR CPYWORD             ; copy word in zero page
        .BYT $58,TMPPTR
        BCC L74E9

L74CC   LDA CHNGFLG             ; get find/change flag
        BEQ L74E4               ; branch if FIND

        INY
        TYA
        CLC
        ADC TMPPTR
        STA TMPPTR
        BCC L74DC

        INC TMPPTR+1
L74DC   LDY #$01
        LDA (TMPPTR),Y
        BEQ L753B

        BNE L74E9               ; branch always

L74E4   JSR READPTR             ; read through temporary pointer
        BEQ L753B

L74E9   LDY #$02
        LDA LINNUM
        CMP (TMPPTR),Y
        LDA LINNUM+1
        INY
        SBC (TMPPTR),Y
        BCC L753B

        INY
        TYA
        EOR $03E0
        STA VERCK
L74FD   LDA (TMPPTR),Y
        BEQ L74CC

        CMP #$22                ; compare with "
        BNE L750D

        LDA VERCK
        EOR #$FF
        STA VERCK
        BNE L755E

L750D   BIT VERCK
        BMI L755E

        LDX $0F
        STY $03E1
L7516   LDA BUF,X               ; get a byte from the input buffer
        BEQ L7536

        CMP #','                ; compare with ","
        BEQ L7536

        CMP #$22                ; compare with "
        BEQ L7536

        CMP (TMPPTR),Y
        BEQ L7532

        CMP #','                ; compare with ","
        BNE L755B

        LDA $03E0
        BEQ L7536

        BNE L755B               ; branch always

L7532   INX
        INY
        BNE L7516

L7536   JSR STOP                ; scan the stop key
        BNE L753E               ; branch if not [STOP]

L753B   JMP L770A

L753E   LDA CHNGFLG             ; get find/change flag
        BNE L7564               ; branch if CHANGE

L7543   LDY #$02
        STY $89
        LDA (TMPPTR),Y
        TAX
        INY
        LDA (TMPPTR),Y
        JSR PRTFIX              ; print .X.A as unsigned integer
        JSR L77A5
        LDA CHNGFLG             ; get find/change flag
        BNE L755B               ; branch if CHANGE

        JMP L74CC

L755B   LDY $03E1
L755E   INY
        BNE L74FD

        JMP $CF08               ; do syntax error then warm start

L7564   JSR CPYWORD             ; copy word in zero page
        .BYT TMPPTR,INDEX
        JSR CPYWORD             ; copy word in zero page
        .BYT VARTAB,$24
        LDA $03E1
        ADC $02CD
        STA $03E1
        DEC $03E1
        LDA $02CE
        SEC
        SBC $02CD
        STA $9E
        BEQ L7595

        CLC
        ADC $03E1
        STA $9F
        BCS L7592

        JSR L75F4
        BEQ L7595

L7592   JSR L75DB
L7595   LDA $03E1
        SEC
        SBC $02CD
        TAY
        INY
        CLC
        ADC $02CE
        STA $03E1
        LDA $02CE
        BEQ L75BC

        STA $02CB
        LDX $02CF
L75B0   LDA BUF,X               ; get a byte from the input buffer
        STA (TMPPTR),Y
        INX
        INY
        DEC $02CB
        BNE L75B0

L75BC   CLC
        LDX #$00
        LDA $9E
        BPL L75C4

        DEX
L75C4   ADC VARTAB              ; add start of variables low byte
        STA VARTAB              ; set start of variables low byte
        TXA
        ADC VARTAB+1            ; add start of variables high byte
        STA VARTAB+1            ; set start of variables high byte
        JMP L7543


;***********************************************************************************;
;
;

L75D0   LDA INDEX
        CMP $24
        BNE L75DA

        LDA INDEX+1
        CMP $25
L75DA   RTS


;***********************************************************************************;
;
;

L75DB   LDY $03E1
        INY
        LDA (INDEX),Y
        LDY $9F
        INY
        STA (INDEX),Y
        JSR L75D0
        BNE L75EC

        RTS

L75EC   INC INDEX
        BNE L75DB

        INC INDEX+1
        BNE L75DB               ; ?? branch always ??


;***********************************************************************************;
;
;

L75F4   LDY $03E1
        LDA ($24),Y
        LDY $9F
        STA ($24),Y
        JSR L75D0
        BNE L7603

        RTS

L7603   LDA $24
        BNE L7609

        DEC $25
L7609   DEC $24
        JMP L75F4

L760E   JMP L733D


;***********************************************************************************;
;
; perform OFF

L7611   LDA #$00                ; no command
        .BYT $2C                ; makes next line BIT $02A9


;***********************************************************************************;
;
; perform TRACE

L7614   LDA #$02                ; TRACE command
        .BYT $2C                ; makes next line BIT $03A9


;***********************************************************************************;
;
; perform STEP

L7617   LDA #$03                ; STEP command
        STA MODE                ; set command mode
        JMP DOREADY             ; set immediate mode and do BASIC warm start


L761E   LDX CHRGOT+2            ; get BASIC execute pointer high byte
        CPX #$02
        BEQ L760E

        LDA CURLIN+1            ; get current line number high byte
        CMP #$FA                ; compare with 64000 ($FA00)
        BCC L7630               ; branch if < 64000

        LDA #$00                ; clear .A
        STA MODE                ; set no command
        BEQ L760E               ; branch always

L7630   LDX $39
        CMP $03E5
        BNE L763C

        CPX TRACELN
L763A   BEQ L760E

L763C   STA $03E5
        STX TRACELN
        LDX #$0B                ; 6 line numbers * 2
L7644   LDA TRACELN,X           ; get TRACE/STEP line number
        STA TRACELN+2,X         ; move down one row
        DEX                     ; decrement index
        BPL L7644               ; repeat for all lines

        BMI L7672               ; branch always

L764F   LDA MODE                ; get command mode
        CMP #$03                ; compare with STEP
        BNE L7661               ; branch if not STEP

L7655   JSR STOP                ; scan the stop key
        BEQ L7666               ; branch if [STOP]

        LDA SHFLAG              ; get keyboard shift/control flag
        BEQ L7655               ; loop while no modifier down

        BNE L7666               ; branch always

L7661   LDA SHFLAG              ; get keyboard shift/control flag
        BNE L7668               ; one or modifiers down

L7666   LDA #$FF
L7668   TAY
L7669   TAX
L766A   INX
        BNE L766A

        INY
        BNE L7669

        BEQ L763A               ; branch always

L7672   LDX #$05                ; six rows - 1
L7674   LDA NUMROWS,X           ; get low byte of screen address for row
        STA $58                         ; save pointer to screen low byte
        STA USER                ; save pointer to colour RAM low byte
        LDA HIBASE              ; get screen memory page
        STA $59                         ; save pointer to screen high byte
        AND #$03                ; mask 0000 00xx, line memory page
        ORA #$94                ; set  1001 01xx, colour memory page
        STA USER+1              ; save pointer to colour RAM low byte
        TXA                     ; copy line index to .A
        ASL                     ; * 2
        TAY                     ; copy line number index to .Y
        STX $8A                 ; save line index
        LDX TRACELN+2,Y         ; get line number low byte
        LDA TRACELN+3,Y         ; get line number high byte
        CMP #$FF                ; compare with inactive row indicator
        BEQ L76B6               ; all lines displayed

        JSR L71FC               ; convert line number to string
        LDY #$00                ; clear .Y
        LDA #'#'
L769C   JSR PUTREV              ; save reverse character and colour to screen
        LDA STACK,Y             ; get character of string from work area
        BNE L769C               ; repeat for whole string

L76A4   CPY #$06                ; compare with end of line
        BCS L76AF               ; branch if line complete

L76A8   LDA #' '
        JSR PUTREV              ; save reverse character and colour to screen
        BNE L76A4               ; branch always

L76AF   LDX $8A                         ; restore line index
        DEX                     ; decrement line index
        BPL L7674               ; while positive repeat for next line

        BMI L764F               ; branch always

L76B6   LDY #$00                ; clear .Y
        BEQ L76A8               ; branch always

        ; save reverse character and colour to screen

PUTREV
        ORA #$80                ; reverse video
        TAX                     ; copy character to .X
        TXA                     ; somewhat pointless
        STA ($58),Y             ; save character to screen address
        PHA                     ; save character
        LDA COLOR               ; get current colour code
        STA (USER),Y            ; save to colour RAM byte
        PLA                     ; restore character
        INY                     ; increment index to next character
        RTS

; low byte of address for trace line numbers (six rows)

NUMROWS
        .BYT $7E,$68,$52,$3C,$26,$10


;***********************************************************************************;
;
; perform DELETE

L76CF   JSR CHRGET              ; increment and scan memory
        JSR LNRANGE             ; parse FROM - TO line number range
        BEQ L76DA               ; parameters parsed ok

        JMP $CF08               ; do syntax error then warm start

L76DA   JSR FINLIN              ; search BASIC for temporary integer line number
        BCC L76EB               ; branch if not found

        LDY #$00
        LDA ($5A),Y
        TAX
        INY
        LDA ($5A),Y
        STA $5B
        STX $5A
L76EB   LDY #$00
        LDA ($5A),Y
        STA ($58),Y
        INC $58
        BNE L76F7

        INC $59
L76F7   INC $5A
        BNE L76FD

        INC $5B
L76FD   JSR L7713
        BNE L76EB

        LDA $58
        STA VARTAB              ; set start of variables low byte
        LDA $59
        STA VARTAB+1            ; set start of variables high byte
L770A   JSR $C659               ; reset execute pointer and do CLR
        JSR LNKPRG              ; rebuild BASIC line chaining
        JMP READY               ; do warm start


;***********************************************************************************;
;
;

L7713   LDX VARTAB              ; get start of variables low byte
        CPX $5A
        BNE L771D

        LDY VARTAB+1            ; get start of variables high byte
        CPY $5B
L771D   RTS


;***********************************************************************************;
;
; parse FROM - TO line number range

LNRANGE
        JSR CPYWORD             ; copy word in zero page
        .BYT TXTTAB,$58
        JSR SETVTAB             ; update start of variables
        JSR CPYWORD             ; copy word in zero page
        .BYT TMPPTR,$5A
        LDX #$FF
        STX LINNUM+1
        JSR CHRGOT              ; scan memory
        BCC L7743               ; branch if numeric character

L7734   CMP #'-'                ; compare with "-"
        BEQ L773C

        CMP #TK_MINUS           ; compare with token for "-"
        BNE L777C               ; if not "-" then exit

L773C   JSR CHRGET              ; increment and scan memory
        BCC L7763               ; branch if numeric character

        BCS L7734               ; branch always

L7743   JSR DECBIN              ; get fixed-point number into temporary integer
        PHA                     ; save next character in command
        JSR FINLIN              ; search BASIC for temporary integer line number
        JSR CPYWORD             ; copy word in zero page
        .BYT TMPPTR,$58
        PLA                     ; restore next character in command
        BEQ L776B               ; branch if no chrs

        LDX #$FF
        STX LINNUM+1
        CMP #'-'                ; compare with "-"
        BEQ L775E

        CMP #TK_MINUS           ; compare with token for "-"
        BNE L777C               ; if not "-" then exit

L775E   JSR CHRGET              ; increment and scan memory
        BCS L777C               ; if not numeric character then exit

L7763   JSR DECBIN              ; get fixed-point number into temporary integer
        BNE L777C               ; exit if not ok

        JSR FINLIN              ; search BASIC for temporary integer line number
L776B   JSR CPYWORD             ; copy word in zero page
        .BYT TMPPTR,$5A
        LDA $5A
        CMP $58
        LDA $5B
        SBC $59
        BCC L777D               ; flag syntax error and return

        LDA #$00                ; flag ok
L777C   RTS

L777D   LDA #$01                ; flag syntax error
        RTS


;***********************************************************************************;
;
; perform HELP

L7780   LDX CURLIN+1            ; get current line number high byte
        STX LINNUM+1
        INX                     ; increment current line number high byte
        BEQ L77A2               ; return if not immediate mode

        LDA $39
        STA LINNUM
        JSR $DDC9               ; print current line
        LDX #$FF                ; set current line high byte to -1, indicates immediate mode
        STX CURLIN+1            ; set current line number high byte
        INX                     ; clear .X
        STX MODE                ; no command
        JSR FINLIN              ; search BASIC for temporary integer line number
        CLC
        LDA $89
        SBC TMPPTR
        STA $89
        JSR L77A5
L77A2   JMP READY               ; do warm start


;***********************************************************************************;
;
;

L77A5   JSR L77AB
        JMP $CAD7               ; print CR/LF


;***********************************************************************************;
;
;

L77AB   LDY #$03
        STY $0B
        STY $8A
        LDA #' '
L77B3   LDY $8A
        AND #$7F                ; clear top bit
L77B7   JSR $CB47               ; display character
        CMP #$22                ; compare with "
        BNE L77C4

        LDA $0B
        EOR #$FF
        STA $0B
L77C4   LDA #$00                ; clear .A
        STA RVS                 ; clear reverse flag
        INY
        CPY $89
        BNE L77CF

        STY RVS                 ; set reverse flag
L77CF   LDA (TMPPTR),Y
        BNE L77D4

        RTS

L77D4   BPL L77B7

        CMP #TK_PI              ; compare with token for PI
        BEQ L77B7

        BIT $0B
        BMI L77B7

        CMP #TK_GO+1            ; compare with first Super Expander token
        BCC L77EB               ; standard BASIC token, continue

        STY $8A                 ; save .Y
        JSR $AFFD               ; call into Super Expander
        LDY $8A                 ; restore .Y
        BNE L77C4

L77EB   SBC #$7E
        TAX
        STY $8A
        LDY #$FF
L77F2   DEX
        BEQ L77FD

L77F5   INY
        LDA RESLST,Y            ; BASIC keywords
        BPL L77F5

        BMI L77F2               ; branch always

L77FD   INY
        LDA RESLST,Y            ; BASIC keywords
        BMI L77B3

        JSR $CB47               ; display character
        BNE L77FD               ; branch always


;***********************************************************************************;
;
; perform AUTO

L7808   JSR PARSEAR             ; parse parameters for AUTO/RENUMBER
        JSR L784B
        LDA #$01                ; AUTO command
        STA MODE                ; set command mode
        LDA #$00                ; clear .A
        RTS


;***********************************************************************************;
;
;

L7815   PLA                     ; restore BASIC byte
        PHA                     ; save BASIC byte again
        BNE L7822               ; not null so continue, otherwise ...

        LDA #$00                ; clear .A, somewhat pointless
        STA MODE                ; set command mode, no command
        STA NDX                 ; clear keyboard buffer index
L781F   JMP L733D

L7822   CMP #' '                ; compare with " "
        BEQ L781F

        CMP #':'                ; compare with ":"
        BCS L782E;              ; not numeric

        CMP #'0'                ; compare with "0"
        BCS L781F               ; numeric

L782E   LDA LINNUM
        TAY
        CMP AUTONXT             ; compare with AUTO next line number low byte
        LDA LINNUM+1
        TAX
        SBC AUTONXT+1           ; subtract AUTO next line number high byte
        BCC L7846

        STY AUTONXT             ; set AUTO next line number low byte
        STX AUTONXT+1           ; set AUTO next line number high byte
        JSR ADDINC              ; add increment to AUTO next line number
        BCC L7846               ; branch if < 64000

        JMP RANGERR             ; do out of range error then warm start

L7846   JSR L784B
        BPL L781F               ; branch always


;***********************************************************************************;
;
;

L784B   JSR L71F8
        LDY #$00
L7850   INY
        LDA STACK,Y
        STA KEYD-1,Y
        BNE L7850

        LDA #' '
        STA KEYD-1,Y
        STY NDX                 ; set keyboard buffer index
        RTS


;***********************************************************************************;
;
; perform DUMP

L7861   JSR CPYWORD             ; copy word in zero page
        .BYT VARTAB,TMPPTR      ; copy start of variables to temporary pointer
L7866   LDA TMPPTR              ; get temporary pointer low byte
        CMP ARYTAB              ; compare with end of variables low byte
        LDA TMPPTR+1            ; get temporary pointer high byte
        SBC ARYTAB+1            ; subtract end of variables high byte
        BCC L7873               ; continue if less than

        JMP DOREADY             ; set immediate mode and do BASIC warm start

L7873   LDY #$00                ; clear .Y
        STY $8A                 ; clear variable type flags
        INY                     ; increment index to second variable name byte
L7878   LDA (TMPPTR),Y          ; get variable name byte
        ASL                     ; shift top bit into Cb
        ROL $8A                 ; shift top bit into variable type
        LSR                     ; restore variable name byte, Cb was clear
        STA VARNAM,Y            ; set variable name byte
        DEY                     ; decrement index
        BPL L7878               ; loop for both variable name bytes

        LDX $8A                 ; get variable type
        BEQ L78B1               ; both top bits were clear, floating-point

        DEX
        BEQ L78F0               ; first byte was set, second clear, invalid type

        DEX
        BEQ L78C9               ; top bit of first byte was clear, string

        ; integer variable

        JSR PRTVNAM             ; display variable name
        LDA #'%'
        JSR $CB47               ; display character
        LDA #'='
        JSR $CB47               ; display character
        LDY #$02                ; offset to value high byte
        LDA (TMPPTR),Y          ; get value high byte
        PHA                     ; save value high byte
        INY                     ; increment to offset to value low byte
        LDA (TMPPTR),Y          ; get value low byte
        TAY                     ; copy value low byte to .Y
        PLA                     ; restore value high byte
        JSR MAKFP               ; convert fixed integer .A.Y to float FAC1
L78A8   JSR FLTASC              ; convert FAC1 to ASCII string result in (.A.Y)
        JSR PRTSTR              ; print null terminated string
        JMP L78ED

        ; floating-point variable

L78B1   JSR PRTVNAM             ; display variable name
        LDA #'='
        JSR $CB47               ; display character
        JSR RETVP               ; return variable
        LDA VARPNT              ; get current variable address low byte
        LDY VARPNT+1            ; get current variable address high byte
        JSR LODFAC              ; unpack memory (.A.Y) into FAC1
        JMP L78A8               ; convert FAC1 to ASCII and print

L78C6   .BYT $22,"=$"

        ; string variable

L78C9   JSR PRTVNAM             ; display variable name
        LDX #$02                ; string length - 1
L78CE   LDA L78C6,X             ; get string byte
        JSR $CB47               ; display character
        DEX                     ; decrement index
        BPL L78CE               ; loop until all done

        LDY #$04                ; index to value address high byte
        LDA (TMPPTR),Y          ; get value address high byte
        STA INDEX+1             ; set utility pointer high byte
        DEY                     ; decrement to value address low byte
        LDA (TMPPTR),Y          ; get value address low byte
        STA INDEX               ; set utility pointer low byte
        DEY                     ; decrement to value length
        LDA (TMPPTR),Y          ; get value length
        JSR $CB24               ; print string from utility pointer
        LDA #$22                ; double quote
        JSR $CB47               ; display character
L78ED   JSR $CAD7               ; print CR/LF
L78F0   JSR STOP                ; scan the stop key
        BNE L78F8               ; branch if not [STOP]

        JMP DOREADY             ; set immediate mode and do BASIC warm start

L78F8   LDA SHFLAG              ; get keyboard shift/control flag
        BNE L78F8               ; loop while a modifier down

        CLC
        LDA TMPPTR              ; get temporary pointer low byte
        ADC #$07                ; add length of each variable definition
        STA TMPPTR              ; set temporary pointer low byte
        BCC L7908               ; branch if no carry

        INC TMPPTR+1            ; increment temporary pointer high byte
L7908   JMP L7866               ; check if end of variables reached


;***********************************************************************************;
;
; display variable name

PRTVNAM
        LDA VARNAM              ; get current variable name first byte
        JSR $CB47               ; display character
        LDA VARNAM+1            ; get current variable name second byte
        BEQ L7929               ; skip if zero

        JMP $CB47               ; display character


;***********************************************************************************;
;
; update start of variables

SETVTAB
        JSR STOSTRT             ; store address of start of memory in temporary pointer
L791A   JSR READPTR             ; read through temporary pointer
        BNE L791A               ; repeat until zero

        CLC
        TXA                     ; copy address low byte to .A
        ADC #$02
        STA VARTAB              ; set start of variables low byte
        BCC L7929               ; exit if no carry

        INC VARTAB+1            ; increment start of variables high byte
L7929   RTS

BANNER
        .BYT $0D," DEVELOPERS' AID V",DA_VERSION,$0D,$00


;***********************************************************************************;
;
; perform KEY

L7943   JSR CHRGET              ; increment and scan memory
        BEQ L79A7               ; if no more chrs just display all key definitions

        JSR CRNCH2              ; crunch BASIC token
        JSR CHRGET              ; increment and scan memory
        JSR $D79E               ; get byte parameter
        CPX #$0D                ; compare with 12 + 1
        BCS L7998               ; if >= do illegal quantity error

        DEX                     ; decrement function key number
        BMI L7998               ; if was zero do illegal quantity error

        STX $02CB
        JSR COMCHK              ; scan for ","
        JSR FRMEVL              ; evaluate expression
        JSR DELST               ; evaluate string
        CMP #$0B                ; compare with maximum length + 1
        BCS L7998               ; if >= do illegal quantity error

        TAY
        DEY
        BMI L7998               ; if = 0 do illegal quantity error

        LDX #$09                ; maximum length - 1
        LDA #$00                ; clear .A
L7970   STA TBUFFR,X
        DEX                     ; decrement index
        BPL L7970               ; loop until done

L7976   LDA (INDEX),Y
        STA TBUFFR,Y
        DEY
        BPL L7976

        LDX $02CB
        LDY L799B,X
        LDX #$09                ; maximum length - 1
L7986   LDA TBUFFR,X
        CMP #$1F                ; compare with [<-]
        BNE L798F

        LDA #$0D                ; replace with [CR]
L798F   STA (MEMSIZ),Y          ; save character
        DEY                     ; decrement destination index
        DEX                     ; decrement source index
        BPL L7986               ; loop until done

L7995   JMP DOREADY             ; set immediate mode and do BASIC warm start

L7998   JMP ILQUAN              ; do illegal quantity error


L799B   .BYT 9,19,29,39,49,59,69,79,89,99,109,119


;***********************************************************************************;
;
; display all key definitions

L79A7   LDX #$00                ; index of first function key
L79A9   LDY FKEYSTOR,X          ; get offset of first byte of definition
        JSR L79B6               ; display key definition of .X
        INX                     ; increment index
        CPX #$0C                ; 12 function keys
        BNE L79A9               ; loop until all done

        BEQ L7995               ; branch always


;***********************************************************************************;
;
; display key definition of .X
;
; .Y contains the offset to the start of the key definition.

L79B6   LDA #'K'
        JSR CHROUT              ; output character to channel
        LDA #'E'
        JSR CHROUT              ; output character to channel
        LDA #'Y'
        JSR CHROUT              ; output character to channel
        LDA #' '
        CPX #$09
        BCC L79CD               ; branch if single digit

        LDA #'1'                ; most significant digit
L79CD   JSR CHROUT              ; output character to channel
        LDA L7A25,X             ; get least significant digit
        JSR CHROUT              ; output character to channel
        LDA #','
        JSR CHROUT              ; output character to channel
        LDA #$22                ; double quote
        JSR CHROUT              ; output character to channel
        STX $02CB
        LDX #$0A                ; maximum length
        STX INSRT               ; set insert count
L79E7   LDA (MEMSIZ),Y          ; get key value
        BEQ L79EE               ; skip if NUL

        JSR L7A04               ; output character
L79EE   LDA (MEMSIZ),Y          ; get key value
        BEQ L79F6

        INY
        DEX
        BNE L79E7

L79F6   LDA #$22                ; double quote
        JSR CHROUT              ; output character to channel
        LDA #$0D                ; [CR]
        JSR CHROUT              ; output character to channel
        LDX $02CB
        RTS


;***********************************************************************************;
;
; output character, translate [CR] to reverse [<-]

L7A04   CMP #$0D                ; compare with [CR]
        BEQ L7A0B               ; display reverse left arrow instead

        JMP CHROUT              ; output character to channel

L7A0B   LDA #$01                ; reverse on
        STA RVS                 ; set reverse flag
        LDA #$5F                ; left arrow
        JSR CHROUT              ; output character to channel
        LDA #$00                ; reverse off
        STA RVS                 ; clear reverse flag
        RTS


; offset to function key definition

FKEYSTOR
        .BYT 0,10,20,30,40,50,60,70,80,90,100,110

; least significant digit of function key number

L7A25   .BYT "123456789012"


;***********************************************************************************;
;
; perform KILL

L7A31   LDX #$1C                ; set byte count
L7A33   LDA CGIMAG,X            ; get byte from KERNAL table
        STA CHRGET,X            ; save byte in page zero
        DEX                     ; decrement count
        BPL L7A33               ; loop if not all done

        JMP DOREADY             ; set immediate mode and do BASIC warm start


;***********************************************************************************;
;
; keyboard decode handler

KEYBDEC
        LDX #$03                ; number of keys - 1
        LDA SFDX                ; get which key
L7A42   CMP FNSCAN,X            ; compare with function key
        BEQ L7A4D               ; branch if equal

        DEX                     ; decrement index
        BPL L7A42               ; loop for all function keys

        JMP L7BCB               ; handle special editing functions

L7A4D   CMP LSTX                ; compare with last key
        BEQ L7A75               ; if equal restore column state and exit

        STA LSTX                ; save as last key pressed
        STX $02B4               ; save base function key scan code
        LDY SHFLAG              ; get keyboard shift/control flag
        LDA FKEYOFF,Y           ; get function key offset
        ORA $02B4               ; OR with base function key scan code
        TAX                     ; copy function key index to .X
        LDY LASTVAL,X           ; get index of last key value
        LDX #$0A                ; maximum length
        STX NDX                 ; set keyboard buffer index
        DEX                     ; decrement index
L7A68   LDA (MEMSIZ),Y          ; get key value
        BNE L7A6E               ; branch if not NUL

        DEC NDX                 ; decrement keyboard buffer index
L7A6E   STA KEYD,X              ; keyboard buffer
        DEY                     ; decrement source index
        DEX                     ; decrement destination index
        BPL L7A68               ; loop for all values

L7A75   JMP $EBD6               ; restore column state


        ; function key scan codes

FNSCAN
        .BYT $27,$2F,$37,$3F

        ; key modifier offsets

FKEYOFF
        .BYT $00,$04,$00,$04,$08,$04,$08,$04

        ; offsets of last key value

LASTVAL
        .BYT 9,29,49,69,19,39,59,79,89,99,109,119


;***********************************************************************************;
;
; program mode function key values

PROGKEYS
        .BYT "LIST ",$00,$00,$00,$00,$00
        .BYT "MID$(",$00,$00,$00,$00,$00
        .BYT "RUN",$0D,$00,$00,$00,$00,$00,$00
        .BYT "LEFT$(",$00,$00,$00,$00
        .BYT "GOTO",$00,$00,$00,$00,$00,$00
        .BYT "RIGHT$(",$00,$00,$00
        .BYT "INPUT",$00,$00,$00,$00,$00
        .BYT "CHR$(",$00,$00,$00,$00,$00
        .BYT "EDIT",$0D,$00,$00,$00,$00,$00     ; [Ctrl] [F1]
        .BYT "GOSUB",$00,$00,$00,$00,$00        ; [Ctrl] [F3]
        .BYT "RETURN",$0D,$00,$00,$00           ; [Ctrl] [F5]
        .BYT "STR$(",$00,$00,$00,$00,$00        ; [Ctrl] [F7]


;***********************************************************************************;
;
; edit mode function key values

EDITKEYS
        .BYT "LIST ",$00,$00,$00,$00,$00
        .BYT "AUTO",$00,$00,$00,$00,$00,$00
        .BYT "RUN",$0D,$00,$00,$00,$00,$00,$00
        .BYT "DELETE",$00,$00,$00,$00
        .BYT "FIND",$00,$00,$00,$00,$00,$00
        .BYT "CHANGE",$00,$00,$00,$00
        .BYT "TRACE",$0D,$00,$00,$00,$00
        .BYT "STEP",$0D,$00,$00,$00,$00,$00
        .BYT "PROG",$0D,$00,$00,$00,$00,$00     ; [Ctrl] [F1]
        .BYT "RENUMBER",$00,$00                 ; [Ctrl] [F3]
        .BYT "MERGE",$00,$00,$00,$00,$00        ; [Ctrl] [F5]
        .BYT "OFF",$0D,$00,$00,$00,$00,$00,$00  ; [Ctrl] [F7]


;***********************************************************************************;
;
; lower top of memory for function key storage

LOWERMEM
        SEC
        LDA MEMHIGH             ; get memory top low byte
        SBC #KEYTBLSZ           ; subtract 10 bytes for each function key
        STA MEMHIGH             ; set memory top low byte
        STA MEMSIZ              ; set end of memory low byte
        STA MEMSIZ              ; set end of memory low byte
        LDA MEMHIGH+1           ; get memory top high byte
        SBC #$00                ; subtract carry
        STA MEMHIGH+1           ; set memory top low byte
        STA $38
        LDY #KEYTBLSZ-1         ; size to copy
L7B99   LDA PROGKEYS,Y          ; get key value from table
        STA (MEMSIZ),Y          ; set key value
        DEY                     ; decrement index
        BPL L7B99               ; loop for all key values
        LDA #$04
        STA $02B4               ; ?? unused ??
        RTS


;***********************************************************************************;
;
; perform PROG

L7BB1   LDY #KEYTBLSZ-1         ; size to copy
L7BB3   LDA PROGKEYS,Y          ; get key value from table
        STA (MEMSIZ),Y          ; set key value
        DEY                     ; decrement index
        BPL L7BB3               ; loop for all key values

        JMP DOREADY             ; set immediate mode and do BASIC warm start


;***********************************************************************************;
;
; perform EDIT

L7BBE   LDY #KEYTBLSZ-1         ; size to copy
L7BC0   LDA EDITKEYS,Y          ; get key value from table
        STA (MEMSIZ),Y          ; set key value
        DEY                     ; decrement index
        BPL L7BC0               ; loop for all key values

        JMP DOREADY             ; set immediate mode and do BASIC warm start


;***********************************************************************************;
;
; handle special editing functions

L7BCB   LDA SHFLAG              ; get keyboard shift/control flag
        AND #$04                ; mask [CTRL] bit
        BNE L7BD5               ; branch if [CTRL] pressed

L7BD2   JMP SETKEYS             ; evaluate SHIFT/CTRL/C= keys and return

L7BD5   LDA SFDX                ; get which key
        CMP #$15                ; compare with 'L'
        BEQ L7C08               ; erase all characters after the cursor on the same line

        CMP #$1C                ; compare with 'N'
        BEQ L7C18               ; erase all characters in the program after the cursor

        CMP #$31                ; compare with 'E'
        BEQ L7C10               ; cancel quotes in insert mode

        CMP #$33                ; compare with 'U'
        BEQ L7BF5               ; erases all the characters on the line containing the cursor

        CMP #$30                ; compare with 'Q'
        BNE L7BEE

        JMP L7C6E               ; scroll up

L7BEE   CMP #$11                ; compare with 'A'
        BNE L7BD2               ; if not 'A' then evaluate SHIFT/CTRL/C= keys and return

        JMP L7D11               ; scroll down


;***********************************************************************************;
;
; Ctrl-U - erases all the characters on the line containing the cursor

L7BF5   JSR CLRBLNK             ; turn off blinking cursor
        LDY #$00
        STY PNTR                ; set cursor column
L7BFC   LDA #' '
        .BYT $24                ; makes next line BIT $C8
L7BFF   INY                     ; increment index
        STA (PNT),Y             ; save space to current screen line
        CPY LNMX                ; compare with current screen line length
        BNE L7BFF               ; loop until end of line

        BEQ L7BD2               ; evaluate SHIFT/CTRL/C= keys and return, branch always


;***********************************************************************************;
;
; Ctrl-L - erase all characters after the cursor on the same line

L7C08   JSR CLRBLNK             ; turn off blinking cursor
        LDY PNTR                ; get cursor column
        JMP L7BFC


;***********************************************************************************;
;
; Ctrl-E - cancel quotes in insert mode

L7C10   LDA #$00
        STA INSRT               ; set insert count
        STA QTSW                ; clear cursor quote flag
        BEQ L7BD2               ; evaluate SHIFT/CTRL/C= keys and return, branch always


;***********************************************************************************;
;
; Ctrl-N - erase all characters in the program after the cursor

L7C18   JSR CLRBLNK             ; turn off blinking cursor
        LDA PNT+1               ; get current screen line pointer high byte
        PHA                     ; save current screen line pointer high byte
        LDA PNT                 ; get current screen line pointer low byte
        PHA                     ; save current screen line pointer low byte
        CLC
        ADC PNTR                ; add cursor column
        TAY                     ; copy cursor page offset to .Y
        LDA #$00                ; clear .A
        STA PNT                 ; clear current screen line pointer low byte
        ADC PNT+1               ; add current screen line pointer high byte
        STA PNT+1               ; set current screen line pointer high byte
        LDX HIBASE              ; get screen memory page
        INX                     ; increase by ..
        INX                     ; .. two pages
        LDA #' '
L7C34   STA (PNT),Y             ; save space to current screen line
        INY                     ; increment cursor page offset
        BNE L7C34               ; repeat to end of page

        INC PNT+1               ; increment current screen line pointer high byte
        CPX PNT+1               ; compare with current screen line pointer high byte
        BNE L7C34               ; repeat to end of screen

        LDX TBLX                ; get cursor row
L7C41   INX                     ; increment cursor row
        CPX #$18                ; compare with number of lines + 1
        BEQ L7C4E               ; if at end of link table restore pointer and return

        LDA LDTB1,X             ; get start of line X pointer high byte
        ORA #$80                ; mark as start of logical line
        STA LDTB1,X             ; set start of line X pointer high byte
        BNE L7C41               ; branch always

L7C4E   PLA                     ; restore current screen line pointer low byte
        STA PNT                 ; set current screen line pointer low byte
        PLA                     ; restore current screen line pointer high byte
        STA PNT+1               ; set current screen line pointer high byte
        JMP SETKEYS             ; evaluate SHIFT/CTRL/C= keys


;***********************************************************************************;
;
; turn off blinking cursor

CLRBLNK
        LDA BLNON               ; get cursor blink phase
        BEQ L7C6D               ; exit if cursor phase

        LDY #$00                ; clear .Y
        STY BLNON               ; clear cursor blink phase
        LDY PNTR                ; get cursor column
        LDA CDBLN               ; get character under cursor
        STA (PNT),Y             ; save character to current screen line
        JSR COLORSYN            ; calculate pointer to colour RAM
        LDA GDCOL               ; get colour under cursor
        STA (USER),Y            ; save to colour RAM
L7C6D   RTS


;***********************************************************************************;
;
; Ctrl-Q - scroll up

L7C6E   LDX TBLX                ; get cursor row
        BEQ L7C7E

        LDA #$01                ; [SHIFT]
        STA SHFLAG              ; set keyboard shift/control flag
        LDA #$1F                ; [CRSR D]
        STA SFDX                ; set which key
L7C7B   JMP SETKEYS             ; evaluate SHIFT/CTRL/C= keys

L7C7E   LDA $02CA
        BNE L7C7B

        INC $02CA
        INC BLNSW               ; disable cursor
        JSR CLRBLNK             ; turn off blinking cursor
        LDX #$FF
L7C8D   INX
        CPX #$17
        BEQ L7CB7

        LDA LDTB1,X             ; get start of line .X pointer high byte
        BPL L7C8D

        LDY LDTB2,X             ; get low byte screen line addresses
        STY CHRGOT+1            ; set BASIC execute pointer low byte
        AND #$01
        ORA HIBASE              ; OR with screen memory page
        STA CHRGOT+2            ; set BASIC execute pointer high byte
        JSR L7D97
        BCS L7C8D

        JSR DECBIN              ; get fixed-point number into temporary integer
        JSR FINLIN              ; search BASIC for temporary integer line number
        LDA TMPPTR
        LDX TMPPTR+1
        CMP TXTTAB              ; compare with start of memory low byte
        BNE L7CB9

        CPX TXTTAB+1            ; compare with start of memory high byte
L7CB7   BEQ L7D09

L7CB9   STA FNADR               ; set file name pointer low byte
        DEX
        STX FNADR+1             ; set file name pointer high byte
        LDY #$FF
L7CC0   INY
        LDA (FNADR),Y           ; get file name byte
L7CC3   TAX
        BNE L7CC0

        INY
        LDA (FNADR),Y           ; get get file name byte
        CMP TMPPTR
        BNE L7CC3

        INY
        LDA (FNADR),Y           ; get get file name byte
        CMP TMPPTR+1
        BNE L7CC3

        DEY
        TYA
        CLC
        ADC FNADR               ; add file name pointer low byte
        STA TMPPTR
        LDA FNADR+1             ; get file name pointer high byte
        ADC #$00
        STA TMPPTR+1
        JSR CLRBLNK             ; turn off blinking cursor
        JSR L7DC7               ; scroll screen up
        JSR HOME                ; home cursor
        LDY #$02
        LDA (TMPPTR),Y
        TAX
        INY
        LDA (TMPPTR),Y
        JSR PRTFIX              ; print .X.A as unsigned integer
        LDX #$00
        STX $89
        INX
        STX AUTODN              ; set screen scrolling flag
        JSR L77AB
        JSR CLREDIT             ; clear insert, quote, reverse flags
        JSR CLRBLNK             ; turn off blinking cursor
        JSR HOME                ; home cursor
L7D09   DEC BLNSW               ; enable cursor
        DEC $02CA
        JMP $EBD6               ; restore column state


;***********************************************************************************;
;
; Ctrl-A - scroll down

L7D11   LDX TBLX                ; get cursor row
        CPX #$16                ; compare with max
        BEQ L7D23

        LDA #$00                ; clear .A
        STA SHFLAG              ; clear keyboard shift/control flag
        LDA #$1F                ; [CRSR D]
        STA SFDX                ; set which key
L7D20   JMP SETKEYS             ; evaluate SHIFT/CTRL/C= keys

L7D23   LDA $02CA
        BNE L7D20

        INC $02CA
        INC BLNSW               ; disable cursor
        JSR CLRBLNK             ; turn off blinking cursor
        LDX #$17
L7D32   DEX
        BMI L7D8F

        LDA LDTB1,X             ; get start of line .X pointer high byte
        BPL L7D32               ; loop if not logical line start

        LDY LDTB2,X             ; get low byte screen line addresses
        STY CHRGOT+1            ; set BASIC execute pointer low byte
        AND #$01
        ORA HIBASE              ; OR with screen memory page
        STA CHRGOT+2            ; set BASIC execute pointer high byte
        JSR L7D97
        BCS L7D32

        JSR DECBIN              ; get fixed-point number into temporary integer
        INC LINNUM
        BNE L7D53

        INC LINNUM+1
L7D53   JSR FINLIN              ; search BASIC for temporary integer line number
        BCS L7D5A               ; branch if found

        BEQ L7D8F

L7D5A   JSR CLRBLNK             ; turn off blinking cursor
        LDA #$8D                ; [SHIFT] [CR]
        JSR CHROUT              ; output character to channel
        LDY #$02
        LDA (TMPPTR),Y
        TAX
        INY
        LDA (TMPPTR),Y
        JSR PRTFIX              ; print .X.A as unsigned integer
        JSR L77AB
        JSR CLREDIT             ; clear insert, quote, reverse flags
        JSR CLRBLNK             ; turn off blinking cursor
        LDY PNTR                ; get cursor column
        BEQ L7D89               ; if start of line restore state and return

L7D7A   CPY #$16                ; compare with start of physical line 2
        BEQ L7D89               ; if start of line restore state and return

        CPY #$2C                ; compare with start of physical line 3
        BEQ L7D89               ; if start of line restore state and return

        CPY #$42                ; compare with start of pyhsical line 4
        BEQ L7D89               ; if start of line restore state and return

        DEY                     ; decrement cursor column
        BNE L7D7A               ; repeat until start of physical line found

L7D89   LDA #$16
        STA TBLX                ; set cursor row
        STY PNTR                ; set cursor column
L7D8F   DEC $02CA
        DEC BLNSW               ; enable cursor
        JMP $EBD6               ; restore column state


;***********************************************************************************;
;
;

L7D97   LDY MODE                ; get command mode
        CPY #$01                ; compare with AUTO
        BNE L7D9F

        DEC MODE                ; set command mode, no command
L7D9F   LDY #$00
        STY $02B6
        BEQ L7DB6               ; branch always

L7DA6   INC CHRGOT+1            ; increment BASIC execute pointer low byte
        BNE L7DAC               ; branch of no carry

        INC CHRGOT+2            ; increment BASIC execute pointer high byte
L7DAC   INC $02B6
        LDA $02B6
        CMP #$16
        BCS L7DC6

L7DB6   LDA (CHRGOT+1),Y        ; get BASIC byte
        CMP #':'                ; compare with ":"
        BCS L7DC6               ; exit if >=

        CMP #' '                ; compare with " "
        BEQ L7DA6               ; if " " go do next

        SEC
        SBC #'0'                ; subtract "0"
        SEC
        SBC #$D0                ; subtract -"0", clear carry if byte = "0"-"9"
L7DC6   RTS


;***********************************************************************************;
;
; scroll screen up

L7DC7   LDX #$17                ; 23 rows
L7DC9   DEX                     ; decrement line number
        BEQ L7DDB

        JSR LINPTR              ; set start of line .X
        LDA LDTB2-1,X           ; get start of previous line low byte from ROM table
        STA $AC                         ; save previous line pointer low byte
        LDA LDTB1-1,X           ; get start of previous line pointer high byte
        JSR MOVLIN              ; shift screen line up/down
        BMI L7DC9               ; branch always

L7DDB   JSR CLRALINE            ; clear screen line .X
        LDX #$15                ; set index to last screen row - 1
L7DE0   LDA LDTB1+1,X           ; get start of next line pointer high byte
        AND #$7F                ; clear start of logical line bit
        LDY LDTB1,X             ; get start of line .X pointer high byte
        BPL L7DEA               ; branch if start of logical line bit clear

        ORA #$80                ; mark start of logical line bit
L7DEA   STA LDTB1+1,X           ; set start of next line pointer high byte
        DEX                     ; decrement index
        BPL L7DE0

        LDA LDTB1               ; get start of line X pointer high byte
        ORA #$80                ; set start of logical line bit
        STA LDTB1               ; set start of line X pointer high byte
        RTS


;***********************************************************************************;
;
; clear insert, quote, reverse flags

CLREDIT
        LDA #$00                ; clear .A
        STA QTSW                ; clear cursor quote flag
        STA INSRT               ; set insert count
        STA RVS                 ; clear reverse flag
        RTS

MERGERR
        .BYT $0D,"?MERGE ERROR",$0D,$00


;***********************************************************************************;
;
; perform MERGE

L7E0E   JSR CHRGET              ; increment and scan memory
        LDA CHRGOT+1            ; get BASIC execute pointer low byte
        STA $02CB               ; save BASIC execute pointer low byte
        JSR PARSL               ; get parameters for LOAD/SAVE
        JSR L7FB6
        LDA $02CB               ; restore BASIC execute pointer low byte
        STA CHRGOT+1            ; set BASIC execute pointer low byte
        LDA #>BUF               ; input buffer high byte
        STA CHRGOT+2            ; set BASIC execute pointer high byte
        LDA #$00                ; flag load
        STA VERCK               ; set load/verify flag
        JSR PARSL               ; get parameters for LOAD/SAVE
        LDA VERCK               ; get load/verify flag
        LDX TXTTAB              ; get start of memory low byte
        LDY TXTTAB+1            ; get start of memory high byte
        JSR LOAD                ; load RAM from a device
        BCS L7E47               ; branch if error

        JSR LNKPRG              ; rebuild BASIC line chaining
        SEC
        LDY MEMSIZ              ; get end of memory low byte
        LDA $38
        SBC #$01
        CPY INDEX
        SBC INDEX+1
        BCS L7E56

L7E47   LDA #<MERGERR           ; set "?MERGE ERROR" pointer low byte
        LDY #>MERGERR           ; set "?MERGE ERROR" pointer high byte
        JSR PRTSTR              ; print null terminated string
        LDA TXTTAB              ; get start of memory low byte
        LDX TXTTAB+1            ; get start of memory high byte
        STA INDEX
        STX INDEX+1
L7E56   LDA INDEX
        LDX INDEX+1
        STA $5A
        STX $5B
        LDY #$00
L7E60   LDA (MEMSIZ),Y
        STA ($5A),Y
        INC $5A
        BNE L7E6A

        INC $5B
L7E6A   LDA MEMSIZ              ; get end of memory low byte
        CMP $02A1
        LDA $38
        SBC $02A2
        INC MEMSIZ              ; increment end of memory low byte
        BNE L7E7A

        INC $38
L7E7A   BCC L7E60

        LDA $02A1
        STA MEMSIZ              ; set end of memory low byte
        LDA $02A2
        STA $38
        CLC
        LDA INDEX
        ADC $02A3
        STA VARTAB              ; set start of variables low byte
        LDA INDEX+1
        ADC $02A4
        STA VARTAB+1            ; set start of variables high byte
        JSR LNKPRG              ; rebuild BASIC line chaining
        SEC
        LDA MEMSIZ              ; get end of memory low byte
        SBC #$06
        STA $62
        TAY
        LDA $38
        SBC #$00
        STA $63
        CPY VARTAB              ; compare with start of variables low byte
        SBC VARTAB+1            ; subtract start of variables high byte
        SBC #$01
        BCS L7EB1

        JMP MEMERR              ; do out of memory error then warm start

L7EB1   LDY #$05
        LDA #$00
L7EB5   STA ($62),Y
        DEY
        BPL L7EB5

L7EBA   LDA TXTTAB              ; get start of memory low byte
        STA $58
        STA TMPPTR
        LDA TXTTAB+1            ; get start of memory high byte
        STA $59
        STA TMPPTR+1
        LDY #$00
        STY $5A
        STY $5B
        INY
        LDA (TMPPTR),Y
        BNE L7ED4

        JMP L7FB0

L7ED4   LDY #$02
        LDA $5A
        CMP (TMPPTR),Y
        INY
        LDA $5B
        SBC (TMPPTR),Y
        BCS L7EF2

        LDA (TMPPTR),Y
        STA $5B
        DEY
        LDA (TMPPTR),Y
        STA $5A
        LDA TMPPTR
        STA $58
        LDA TMPPTR+1
        STA $59
L7EF2   JSR READPTR             ; Read through temporary pointer
        BNE L7ED4

        TAY
        SEC
        LDA ($58),Y
        STA TMPPTR
        SBC $58
        STA $6A
        INY
        LDA ($58),Y
        STA TMPPTR+1
        SBC $59
        STA $6B
        LDA $62
        SBC $6A
        STA $62
        LDA $63
        SBC $6B
        STA $63
        LDY $6A
        DEY
L7F19   LDA ($58),Y
        STA ($62),Y
        DEY
        BNE L7F19

        LDA ($58),Y
        STA ($62),Y
L7F24   LDA TMPPTR
        STA $6C
        LDA TMPPTR+1
        STA $6D
        JSR READPTR             ; Read through temporary pointer
        DEY
L7F30   LDA ($6C),Y
        STA ($58),Y
        INY
        TAX
        BNE L7F30

        CPY #$02
        BNE L7F40

        LDA TMPPTR+1
        BEQ L7F5F

L7F40   CPY #$05
        BCC L7F30

        LDA TMPPTR
        ORA TMPPTR+1
        BEQ L7F5F

        CLC
        TYA
        LDY #$00
        ADC $58
        STA ($58),Y
        TAX
        TYA
        INY
        ADC $59
        STA ($58),Y
        STX $58
        STA $59
        BNE L7F24

L7F5F   LDY #$01
        LDA (TXTTAB),Y          ; get second byte of memory
        BEQ L7F68

        JMP L7EBA

L7F68   LDA TXTTAB              ; get start of memory low byte
        STA TMPPTR
        LDA TXTTAB+1            ; get start of memory high byte
        STA TMPPTR+1
        SEC
        LDA $62
        SBC #$01
        STA CHRGOT+1            ; set BASIC execute pointer low byte
        LDA $63
        SBC #$00
        STA CHRGOT+2            ; set BASIC execute pointer high byte
L7F7D   LDY #$00
L7F7F   INC CHRGOT+1            ; increment BASIC execute pointer low byte
        BNE L7F85

        INC CHRGOT+2            ; increment BASIC execute pointer high byte
L7F85   LDX #$00
        LDA (CHRGOT+1,X)
        STA (TMPPTR),Y
        INY
        TAX
        BNE L7F7F

        CPY #$05
        BCC L7F7F

        STY $8A
        LDY #$01
        LDA (TMPPTR),Y
        BEQ L7FB0

        CLC
        DEY
        LDA $8A
        ADC TMPPTR
        STA (TMPPTR),Y
        TAX
        TYA
        INY
        ADC TMPPTR+1
        STA (TMPPTR),Y
        STX TMPPTR
        STA TMPPTR+1
        BNE L7F7D

L7FB0   JSR $C660               ; perform CLR
        JMP L770A


;***********************************************************************************;
;
;

L7FB6   LDA MEMSIZ              ; get end of memory low byte
        CMP VARTAB              ; compare with start of variables low byte
        LDA $38
        SBC VARTAB+1            ; subtract start of variables high byte
        SBC #$01
        BCS L7FC5

        JMP MEMERR              ; do out of memory error then warm start

L7FC5   LDA VARTAB              ; get start of variables low byte
        SBC TXTTAB              ; subtract start of memory low byte
        STA $02A3
        LDA VARTAB+1            ; get start of variables high byte
        SBC TXTTAB+1            ; subtract start of memory high byte
        STA $02A4
        LDA MEMSIZ              ; get end of memory low byte
        STA $02A1
        LDA $38
        STA $02A2
        LDY #$00
L7FDF   LDA MEMSIZ              ; get end of memory low byte
        BNE L7FE5

        DEC $38
L7FE5   DEC MEMSIZ              ; decrement end of memory low byte
        LDA VARTAB              ; get start of variables low byte
        BNE L7FED

        DEC VARTAB+1            ; decrement start of variables high byte
L7FED   DEC VARTAB              ; decrement start of variables low byte
        LDA (VARTAB),Y
        STA (MEMSIZ),Y
        LDA TXTTAB              ; get start of memory low byte
        CMP VARTAB              ; compare with start of variables low byte
        LDA TXTTAB+1            ; get start of memory high byte
        SBC VARTAB+1            ; subtract start of variables high byte
        BCC L7FDF

        JMP $C644               ; do NEW, CLR, RESTORE and return


;***********************************************************************************;
;
; Developers' Aid

dainit
        ; Kernel Init
        jsr INITMEM
        jsr FRESTOR
        jsr INITVIA
        jsr INITSK

        ; BASIC Init
        jsr INITVCTRS
        jsr INITBA
        JSR LOWERMEM            ; lower top of memory for function key storage
        jsr FREMSG

        LDY #KEYTBLSZ-1         ; offset of last function key definition
L701C   LDA PROGKEYS,Y          ; get program mode key definition
        STA (MEMSIZ),Y          ; save above top of memory
        DEY                     ; decrement index
        BPL L701C               ; loop until done

        lda #$08
        sta DEVNUM

        SEI                     ; disable interrupts
        JSR INITKEYLOG
        JSR DOPATCH             ; patch CHRGOT, display banner and initialize variables
        LDA #$00                ; clear .A
        STA $02CA
        LDX #$FB                ; value for start stack
        TXS                     ; set stack pointer
        JMP READY               ; return to BASIC

;***********************************************************************************;

PERFORM_CMON
        jsr 46080
        jmp DOREADY             ; set immediate mode and do BASIC warm start

;***********************************************************************************;

PERFORM_OLD
        ldy #$01
        tya
        sta (TXTTAB),y
        jsr LNKPRG
        lda $22
        clc
        adc #$02
        sta VARTAB
        lda $23
        adc #$00
        sta VARTAB+1
        jsr CLR
        jmp DOREADY             ; set immediate mode and do BASIC warm start

;***********************************************************************************;

PERFORM_O5SND
        jsr $b0f0
        jmp DOREADY             ; set immediate mode and do BASIC warm start

;***********************************************************************************;

PERFORM_O5RCV
        jsr $b0f5
        jmp DOREADY             ; set immediate mode and do BASIC warm start

;***********************************************************************************;

PERFORM_DIRECTORY
        jsr $b82f
        jmp DOREADY             ; set immediate mode and do BASIC warm start

;***********************************************************************************;

PERFORM_DISKCMD
        jsr CHRGET
        beq get_status
        jsr FRMEVL              ; evaluate expression
        jsr DELST               ; evaluate string
        tay
        beq get_status
        sta INDEX+2             ; cmd length
        ; Send disk command
        lda DEVNUM
        jsr LISTEN
        lda #$6F
        jsr SECOND
        ldy #$00
L01     lda (INDEX),y
        jsr CIOUT
        iny
        cpy INDEX+2
        bne L01
        jsr UNLSN
        jmp DOREADY             ; set immediate mode and do BASIC warm start

get_status:
        lda DEVNUM
        jsr TALK
        lda #$6F
        jsr TKSA
L02     jsr ACPTR
        jsr CHROUT
        cmp #13
        bne L02
        jsr UNTLK
        jmp DOREADY             ; set immediate mode and do BASIC warm start

;***********************************************************************************;

endofdacode

        * = $b0f0
        .dsb (*-endofdacode), 0
        ; yes, set it again
        * = $b0f0
        .bin 2,0,"fastrs.bin"
endofover5code

        * = $b400
        .dsb (*-endofover5code), 0
        ; yes, set it again
        * = $b400
        .bin 2,0,"cmon-46080.prg"

;***********************************************************************************;

PERFORM_BASCAT
        jmp DOREADY

;***********************************************************************************;

endofcode

        ; Padding to full 8K
        * = $c000
        .dsb (*-endofcode), 0
