;Archivo:		Lab5.s
;Dispositivo:		PIC16F887
;Autor;			Fernando Jose Caceros Morales
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		
;Hardware:		Pushbuttons en puerto B, Leds en Puerto C, 7seg en puerto D 
;
;Creado:		2 marzo, 2021
;Ultima modificacion:	2 marzo, 2021
    
PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
 CONFIG FOSC=INTRC_NOCLKOUT ; Oscilador externo de cristal a 1MHz
 CONFIG WDTE=OFF    ; wdt disables (reinicio repetitivo del pic)
 CONFIG PWRTE=ON    ; PWRT enabled (espera de 72ms al iniciar)
 CONFIG MCLRE=OFF   ; El pin de MCLR se utiliza como I/O
 CONFIG CP=OFF	    ; Sin protección de código
 CONFIG CPD=OFF	    ; Sin protección de datos
 
 CONFIG BOREN=OFF   ; Sin reinicio cuándo el voltaje de alimentación baja de 4V
 CONFIG IESO=OFF    ; Reinicio sin cambio de reloj de interno a externo
 CONFIG FCMEN=OFF   ; Cambio de reloj externo a interno en caso de fallo
 CONFIG LVP=ON	    ; programación en bajo voltaje permitida
 
 ;configuration word 2
 CONFIG WRT=OFF	    ; Protección de autoescritura por el programa desactivada
 CONFIG BOR4V=BOR40V ; Reinicio abajo de 4v, (BOR21V=2.1V)
 
 
;***variables a usar****
 
PSECT udata_bank0 
    Cont_Cent:		DS 1 ; 1 byte
    Cont_Dec:		DS 1 ; 1 byte
    banderas:		DS 1 ; 1 byte
    nibble:		DS 2 ; 2 byte
    display_var:	DS 2 ; 2 byte
    
PSECT udata_shr ;memoria compartida
    w_temp:	 DS 1
    status_temp: DS 1
    
;****instrucciones vector reset***

 PSECT resVector, class=CODE, abs, delta=2
 ORG 00h	    ; posición 0000h para el reset
 resetVector:
    PAGESEL main
    goto main
 
;***configuracion del micro***

PSECT intVect, class=CODE,abs, delta=2
ORG 04h
push:
    movwf w_temp
    swapf STATUS, w
    movwf status_temp

isr:
    btfsc RBIF
    call  int_OCB
    btfsc T0IF
    call  int_tm0

pop:
    swapf status_temp, w
    movwf STATUS
    swapf w_temp, f
    swapf w_temp, w
    retfie
 


PSECT code, delta=2, abs
ORG 100h
siete_seg:
    clrf    PCLATH
    bsf	    PCLATH, 0
    andlw   0Fh
    addwf   PCL, F
    retlw   3Fh	    ; 0
    retlw   06h	    ; 1
    retlw   5Bh	    ; 2
    retlw   4Fh	    ; 3
    retlw   66h	    ; 4
    retlw   6Dh	    ; 5
    retlw   7Dh	    ; 6
    retlw   07h	    ; 7
    retlw   7Fh	    ; 8
    retlw   6Fh	    ; 9
    retlw   77h	    ; A
    retlw   7Ch	    ; B
    retlw   39h	    ; C
    retlw   5Eh	    ; D
    retlw   79h	    ; E
    retlw   71h	    ; F
    
    
main:
    call    config_IO	    ;inputs PORTB, outputs PORTA, C, D
    call    Tm0_config	    ;Configuración timer 0
    call    reloj_config    
    call    config_iocb
    call    config_interrup
    banksel PORTA
    clrf    PORTA
    movlw   3Fh
    movwf   PORTC

    
    
    
    
;****loop proncipal*****
    
loop:
    call separar_nibbles
    call preparar_display
    ;call seleccionador
    ;call direccion
    goto loop
    
;****subrutina****

config_IO: 
    banksel ANSEL
    clrf    ANSEL	    ; pines digitales
    clrf    ANSELH
    
    banksel TRISA
    bsf	    TRISB, 0	    ;PORTB, 0 y 1 como entreada
    bsf	    TRISB, 1
    bcf     TRISB, 2
    bcf     TRISB, 3
    clrf    TRISA	    ;PORT A, C y D como salidas
    clrf    TRISC   
    clrf    TRISD
    bcf	    OPTION_REG, 7   ;habilita pull-ups
    bsf	    WPUB, 0	    ;incrementar
    bsf	    WPUB, 1	    ;decrementar
    return

Tm0_config:
    banksel TRISA
    bcf	    T0CS	    ;selección del reloj interno
    bcf	    PSA		    ;asignamos prescaler al Timer0
    bcf	    PS2
    bcf	    PS1
    bsf	    PS0		    ;prescaler a 4
    banksel PORTA
    movlw   125
    movwf   TMR0
    bcf	    T0IF
    return

reloj_config:
    banksel TRISA
    bsf	    IRCF2
    bcf	    IRCF1
    bcf	    IRCF0	    ; reloj a 1MHz 
    return

config_interrup:
    banksel TRISA
    bsf	    GIE
    
    bsf	    RBIE	    ;interrupción del puerto B
    bcf	    RBIF
    
    bsf	    T0IE	    ;interrupción del Timer0
    bcf	    T0IF   
    return

config_iocb:
    banksel TRISA
    bsf	    IOCB, 0
    bsf	    IOCB, 1
    
    banksel PORTA
    movf    PORTB, W
    bcf	    RBIF    
    return

;*RUTINAS DE INTERRUPCIONES*  

int_OCB:
    btfss   PORTB, 0
    incf    PORTA
    btfss   PORTB, 1
    decf    PORTA
    bcf	    RBIF
    return

int_tm0:
    banksel PORTA
    movlw   125
    movwf   TMR0
    bcf	    T0IF
    clrf PORTB
    btfsc banderas, 0
    goto    display_1
    display_0:
    movf    display_var+1, W
    movwf   PORTC
    bsf	    PORTB, 2
    goto    siguiente_display
    display_1:
    movf    display_var, W
    movwf   PORTC
    bsf	    PORTB, 3
    goto    siguiente_display
    siguiente_display:
    movlw   1
    xorwf   banderas, F
    return
    return

    
;**RUTINAS DEL LOOP*
/*seleccionador:
    movlw   6
    subwf   cont_timer0, w	
    btfsc   ZERO
    clrf    cont_timer0
    movf    cont_timer0, w
    call    siete_seg_sel
    movwf   PORTD
    return*/
 
    
separar_nibbles:
    movf    PORTA, w
    andwf   0x0f
    movwf   nibble
    swapf   PORTA, w
    andwf   0x0f
    movwf   nibble+1
    return
    
preparar_display:
    movf    nibble, w
    call    siete_seg
    movwf   display_var
    movf    nibble+1, w
    call    siete_seg
    movwf   display_var+1
    return
    
/*direccion:
    btfss   PORTD,0
    goto    $+3
    movf    display_var,w
    movwf   PORTC
    btfss   PORTD,1
    goto    $+3
    movf    display_var+1,w
    movwf   PORTC
    return*/
  
END


