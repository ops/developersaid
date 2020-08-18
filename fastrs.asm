;**************************************************************************
;**
;** Copyright (c) 1995, 1996, 2002 Daniel Kahlin <daniel@kahlin.net>
;** Written by Daniel Kahlin <daniel@kahlin.net>
;**
;** Modified for Developer's Aid by ops
;**
;** FastRS - (for serialcable)          38400 8N2
;** (conforms to the Over5 SIMPLEREAD/SIMPLEWRITE protocol)
;**
;**
;******

        PROCESSOR 6502


;**************************************************************************
;**
;** dasm -DPAL
;**
;** VIC-20 PAL (1108405 hz) 38400 8N2
;** <cycles per bit>  1108405 / 38400 = 28.864
;**
;**          0     29    58    87   115   144   173   202   231   260
;** (cycles)
;**             29    29    29    28    29    29    29    29    29
;**        _____ _____ _____ _____ _____ _____ _____ _____ _____
;**       |     |     |     |     |     |     |     |     |     |
;**       |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop  stop
;** ______|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|________
;**
;******
        IFCONST PAL
T1      EQU     29
T2      EQU     29
T3      EQU     29
T4      EQU     28
T5      EQU     29
T6      EQU     29
T7      EQU     29
T8      EQU     29
T9      EQU     29
        ENDIF

;**************************************************************************
;**
;** dasm -DNTSC
;**
;** VIC-20 NTSC (1022727 hz) 38400 8N2
;** <cycles per bit>  1022727 / 38400 = 26.634
;**
;**          0     27    53    80   107   133   160   186   213   240
;** (cycles)
;**             27    26    27    27    26    27    26    27    27
;**        _____ _____ _____ _____ _____ _____ _____ _____ _____
;**       |     |     |     |     |     |     |     |     |     |
;**       |start|  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |stop  stop
;** ______|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|_____|________
;**
;******
        IFCONST NTSC
T1      EQU     27
T2      EQU     26
T3      EQU     27
T4      EQU     27
T5      EQU     26
T6      EQU     27
T7      EQU     26
T8      EQU     27
T9      EQU     27
        ENDIF

        INCLUDE "timing.i"

currzp          EQU     $ac
lastzp          EQU     $ae
startaddrzp     EQU     $fb
endaddrzp       EQU     $a3
checksumzp      EQU     $fe
shiftregzp      EQU     $bd
tempzp          EQU     $02
ptempzp         EQU     $a5
slaskzp         EQU     $ff

CMONPrintHex    EQU     $B925
CHROUT          EQU     $ffd2
PrintStr        EQU     $CB1E   ; Print zero terminated string

        ORG     $b0f0

send:
        jsr     Send
        cli
        rts
recv:
        jsr     Receive
        cli
        rts

ResetChecksum:
        lda     #$00
        sta     shiftregzp
        sta     checksumzp
        rts


;**************************************************************************
;**
;** Receiver
;**
;******
Receive:
;* preserve color
        lda     $900f
        pha

        lda     #<Waiting_msg
        ldy     #>Waiting_msg
        jsr     PrintStr

        jsr     Init

        jsr     ResetChecksum
        jsr     GetByte38400    ;Get HEAD
        cmp     #$e7
        bne     r_fl1

        jsr     GetByte38400    ;Get Start address low byte
        sta     startaddrzp
        sec
        sbc     #1
        sta     currzp
        php
        jsr     GetByte38400
        sta     startaddrzp+1   ;Get Start address high byte
        plp
        sbc     #0
        sta     currzp+1

        jsr     GetByte38400    ;Get End address low byte
        sta     endaddrzp
        sec
        sbc     #1
        sta     lastzp
        php
        jsr     GetByte38400    ;Get End address high byte
        sta     endaddrzp+1
        plp
        sbc     #0
        sta     lastzp+1

        jsr     GetByte38400    ;Get header checksum
        cmp     checksumzp
        bne     r_fl1

        jsr     ResetChecksum

        jsr     GetBody38400

        jsr     GetByte38400
        pha     ;checksum to stack

;*** show start and end! ***

        ldx     endaddrzp
        lda     endaddrzp+1
        stx     $ae
        sta     $af
        stx     $2d
        sta     $2e

        jsr     PrintTransferred

        pla     ;checksum from stack
        eor     checksumzp
        bne     r_fl1

        lda     #<ok_msg
        ldy     #>ok_msg
        jsr     PrintStr
        jmp     r_ex1

r_fl1:
        lda     #<checksumerror_msg
        ldy     #>checksumerror_msg
        jsr     PrintStr

r_ex1:

;* restore color
        pla
        sta     $900f
        rts


;**************************************************************************
;**
;** GETBIT macro  (11 cycles)
;**
;******
        MAC     GETBIT          ;11
        lda     $9110           ;4
        lsr                     ;2
        ror     shiftregzp      ;5
        ENDM

;**************************************************************************
;**
;** Receive a byte      38400 8N2
;**
;******
GetByte38400:
        lda     #%00000001
gb_lp1:
        bit     $9110           ;4
        bne     gb_lp1          ;2

        lda     shiftregzp      ;3
        eor     checksumzp      ;3
        sta     checksumzp      ;3

;\/ T1 cycles  (startbit)
        lda     $900f           ;4
        eor     #$02            ;2
        sta     $900f           ;4
        DELAY   T1-10

;\/ T2 cycles  (bit 1)
        GETBIT                  ;11
        DELAY   T2-11

;\/ T3 cycles  (bit 2)
        GETBIT                  ;11
        DELAY   T3-11

;\/ T4 cycles  (bit 3)
        GETBIT                  ;11
        DELAY   T4-11

;\/ T5 cycles  (bit 4)
        GETBIT                  ;11
        DELAY   T5-11

;\/ T6 cycles  (bit 5)
        GETBIT                  ;11
        DELAY   T6-11

;\/ T7 cycles  (bit 6)
        GETBIT                  ;11
        DELAY   T7-11

;\/ T8 cycles  (bit 7)
        GETBIT                  ;11
        DELAY   T8-11

;\/ T9 cycles  (bit 8)
        GETBIT                  ;11

        lda     shiftregzp      ;3
        rts


;**************************************************************************
;**
;** Receive a block     38400 8N2
;**
;** $ac/$ad = start-1
;** $ae/$af = end-1
;**
;******
GetBody38400:
        ldy     #0
gbo_lp1:
        lda     #%00000001      ;2
gbo_lp2:
        bit     $9110           ;4
        bne     gbo_lp2         ;2

        lda     shiftregzp      ;3
        eor     checksumzp      ;3
        sta     checksumzp      ;3

;\/ T1 cycles  (startbit)
        lda     $900f           ;4
        eor     #$02            ;2
        sta     $900f           ;4
        DELAY   T1-10

;\/ T2 cycles  (bit 1)
        GETBIT                  ;11
        DELAY   T2-11

;\/ T3 cycles  (bit 2)
        GETBIT                  ;11
        DELAY   T3-11

;\/ T4 cycles  (bit 3)
        GETBIT                  ;11
        lda     currzp          ;3
        clc                     ;2
        adc     #1              ;2
        sta     currzp          ;3
        php                     ;3
        DELAY   T4-24

;\/ T5 cycles  (bit 4)
        GETBIT                  ;11
        plp                     ;4
        lda     currzp+1        ;3
        adc     #0              ;2
        sta     currzp+1        ;3
        DELAY   T5-23

;\/ T6 cycles  (bit 5)
        GETBIT                  ;11
        sec                     ;2
        lda     currzp          ;3
        sbc     lastzp          ;3
        php                     ;3
        DELAY   T6-22

;\/ T7 cycles  (bit 6)
        GETBIT                  ;11
        plp                     ;4
        lda     currzp+1        ;3
        sbc     lastzp+1        ;3
        php                     ;3
        DELAY   T7-24

;\/ T8 cycles  (bit 7)
        GETBIT                  ;11
        DELAY   T8-11

;\/ T9 cycles  (bit 8)
        GETBIT                  ;11
        DELAY   3               ;3
        lda     shiftregzp      ;3
        sta     (currzp),y      ;6
        DELAY   5               ;5
        plp                     ;4
        bcs     gbo_ex1         ;2
        jmp     gbo_lp1         ;3
gbo_ex1:
        rts


;**************************************************************************
;**
;** Timing!
;**
;******


Twentythree:
        nop             ;2
Twentyone:
        nop             ;2
Nineteen:
        nop             ;2
Seventeen:
        nop             ;2
Fifteen:
        sta     slaskzp ;3
        rts

Twentytwo:
        nop             ;2
Twenty:
        nop             ;2
Eighteen:
        nop             ;2
Sixteen:
        nop             ;2
Fourteen:
        nop             ;2
Twelve:
        rts


;**************************************************************************
;**
;** Initialize ports!
;**
;******
Init:
        sei
        lda     #%00000110
        sta     $9112   ;RS232 Data dir (bit 0=RxD)
        lda     $911c   ;set Txd HI
        ora     #%11100000
        sta     $911c
        rts

;**************************************************************************
;**
;** Print info about transfer
;**
;******
PrintTransferred:
        lda     #<transferred_msg
        ldy     #>transferred_msg
        jsr     PrintStr

PrintRange:
        lda     #"$"
        jsr     CHROUT
        lda     startaddrzp+1
        jsr     CMONPrintHex
        lda     startaddrzp
        jsr     CMONPrintHex
        lda     #"-"
        jsr     CHROUT
        lda     #"$"
        jsr     CHROUT
        lda     endaddrzp+1
        jsr     CMONPrintHex
        lda     endaddrzp
        jmp     CMONPrintHex


;**************************************************************************
;**
;** Strings
;**
;******
Waiting_msg:
        dc.b    "WAITING",0
Sending_msg:
        dc.b    "SENDING",0
ok_msg:
        dc.b    13,"OK",0
checksumerror_msg:
        dc.b    13,"?CHECKSUM", 13, " ERROR",0
transferred_msg:
        dc.b    13,"TRANSFER ",0


;**************************************************************************
;**
;** Sender
;**
;******
Send:
;* preserve color
        lda     $900f
        pha

        lda     #<Sending_msg
        ldy     #>Sending_msg
        jsr     PrintStr

        jsr     Init

        jsr     ResetChecksum

        lda     #$e7
        jsr     SendByte38400   ;Send HEAD
        lda     $2b
        sta     currzp
        sta     startaddrzp
        jsr     SendByte38400   ;Send Start Ad low
        lda     $2c
        sta     currzp+1
        sta     startaddrzp+1
        jsr     SendByte38400   ;Send Start Ad high
        lda     $2d
        sta     lastzp
        sta     endaddrzp
        jsr     SendByte38400   ;Send End Ad low
        lda     $2e
        sta     lastzp+1
        sta     endaddrzp+1
        jsr     SendByte38400   ;Send End Ad high

        lda     checksumzp
        jsr     SendByte38400   ;Send Header checksum

        jsr     ResetChecksum

;*** send body ***
        ldy     #0
s_lp1:
        lda     (currzp),y      ;5*
        jsr     SendByte38400   ;12
        inc     currzp          ;5
        bne     s_skp1          ;3
        inc     currzp+1
s_skp1:
        sec                     ;2
        lda     currzp          ;3
        sbc     lastzp          ;3
        lda     currzp+1        ;3
        sbc     lastzp+1        ;3
        bcc     s_lp1           ;3

        lda     checksumzp
        jsr     SendByte38400           ;Send body checksum

        jsr     PrintTransferred

;* restore color
        pla
        sta     $900f

        rts


;**************************************************************************
;**
;** SENDBIT macro  (20 cycles)
;**
;******
        MAC     SENDBIT         ;20
        sta     $911c           ;4
        lda     #0              ;2
        lsr     shiftregzp      ;5
        ror                     ;2
        ror                     ;2
        ror                     ;2
        ora     tempzp          ;3
        ENDM

;**************************************************************************
;**
;** Send a byte 38400 8N2
;**
;******
SendByte38400:
        sta     shiftregzp      ;3
        sta     $900f           ;4
        eor     checksumzp      ;3
        sta     checksumzp      ;3


        lda     $911c           ;4
        and     #%11011111      ;2
        sta     tempzp          ;3

;\/ T1 cycles  (startbit)
        SENDBIT                 ;20
        DELAY   T1-20

;\/ T2 cycles  (bit 1)
        SENDBIT                 ;20
        DELAY   T2-20

;\/ T3 cycles  (bit 2)
        SENDBIT                 ;20
        DELAY   T3-20

;\/ T4 cycles  (bit 3)
        SENDBIT                 ;20
        DELAY   T4-20

;\/ T5 cycles  (bit 4)
        SENDBIT                 ;20
        DELAY   T5-20

;\/ T6 cycles  (bit 5)
        SENDBIT                 ;20
        DELAY   T6-20

;\/ T7 cycles  (bit 6)
        SENDBIT                 ;20
        DELAY   T7-20

;\/ T8 cycles  (bit 7)
        SENDBIT                 ;20
        DELAY   T8-20

;\/ T9 cycles  (bit 8)
        sta     $911c           ;4

        lda     tempzp          ;3
        ora     #%00100000      ;2
        DELAY   T9-9

;\/ 52 cycles (2 stopbits)
        sta     $911c           ;4
        jsr     Fourteen        ;14
        jsr     Fourteen        ;14
        jsr     Fourteen        ;14
        jsr     Fourteen        ;14

        jsr     Fourteen        ;14

        rts

myend:
        echo    "send ",send
        echo    "recv ",recv
        echo    "myend ",myend

; eof
