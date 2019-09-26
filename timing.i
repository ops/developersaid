;**************************************************************************
;** timing.i
;** Copyright (c) 1996 Daniel Kahlin <tlr@stacken.kth.se>
;**
;** timing macros for 6502
;**
;******



;**************************************************************************
;**
;** DELAY x cycles
;**
;******
        MAC     DELAY
        IF      [{1}]>23
        echo    "WARNING! DELAY to big!"
        ENDIF
        IF      [{1}]==1
        echo    "WARNING! One cycle DELAY not possible!"
        ENDIF
        IF      [{1}]<0
        echo    "WARNING! DELAY negative!"
        ENDIF

        IF      [{1}]==23
        jsr     Twentythree     ;23
        ENDIF
        IF      [{1}]==22
        jsr     Twentytwo       ;22
        ENDIF
        IF      [{1}]==21
        jsr     Twentyone       ;21
        ENDIF
        IF      [{1}]==20
        jsr     Twenty          ;20
        ENDIF
        IF      [{1}]==19
        jsr     Nineteen        ;19
        ENDIF
        IF      [{1}]==18
        jsr     Eighteen        ;18
        ENDIF
        IF      [{1}]==17
        jsr     Seventeen       ;17
        ENDIF
        IF      [{1}]==16
        jsr     Sixteen         ;16
        ENDIF
        IF      [{1}]==15
        jsr     Fifteen         ;15
        ENDIF
        IF      [{1}]==14
        jsr     Fourteen        ;14
        ENDIF
        IF      [{1}]==13
        nop                     ;2
        nop                     ;2
        nop                     ;2
        nop                     ;2
        nop                     ;2
        sta     slaskzp         ;3
        ENDIF
        IF      [{1}]==12
        jsr     Twelve          ;12
        ENDIF
        IF      [{1}]==11
        nop                     ;2
        nop                     ;2
        nop                     ;2
        nop                     ;2
        sta     slaskzp         ;3
        ENDIF
        IF      [{1}]==10
        nop                     ;2
        nop                     ;2
        nop                     ;2
        nop                     ;2
        nop                     ;2
        ENDIF
        IF      [{1}]==9
        nop                     ;2
        nop                     ;2
        nop                     ;2
        sta     slaskzp         ;3
        ENDIF
        IF      [{1}]==8
        nop                     ;2
        nop                     ;2
        nop                     ;2
        nop                     ;2
        ENDIF
        IF      [{1}]==7
        nop                     ;2
        nop                     ;2
        sta     slaskzp         ;3
        ENDIF
        IF      [{1}]==6
        nop                     ;2
        nop                     ;2
        nop                     ;2
        ENDIF
        IF      [{1}]==5
        nop                     ;2
        sta     slaskzp         ;3
        ENDIF
        IF      [{1}]==4
        nop                     ;2
        nop                     ;2
        ENDIF
        IF      [{1}]==3
        sta     slaskzp         ;3
        ENDIF
        IF      [{1}]==2
        nop                     ;2
        ENDIF
        ENDM
