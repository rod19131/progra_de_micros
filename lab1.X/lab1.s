;Archivo:		main.S
;Dispositivo:		PIC16F887
;Autor;			Jose Morales
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		Contador en el Puerto A
;Hardware:		Leds en el Puerto A
;
;Creado:		1 febrero, 2021
;Ultima modificación:	1 febrero, 2021
    
PROCESSOR 16F887
#include <xc.inc>

;CONFIGURATION WORD 1
CONFIG FOSC=INTRC_NOCLKOUT
CONFIG WDTE=OFF
CONFIG PWRTE=ON
CONFIG MCLRE=OFF
CONFIG CP=OFF
CONFIG CPD=OFF
    
CONFIG BOREN=OFF
CONFIG IESO=OFF
CONFIG FCMEN=OFF
CONFIG LVP=ON
    
;CONFIGURATION WORD 2
CONFIG WRT=OFF
CONFIG BOR4V=BOR40V
;**********variables a usar***********    
PSECT udata_bank0
    cont_small: DS 1
    cont_big:	DS 1
;*********instrucciones vector reset**********   
PSECT resVect, class=CODE, abs, delta=2
;---------------------------------vector reset----------------------------------
ORG 00h
resetVec:
    PAGESEL main
    goto main
;**********configuracion del micro**********    
PSECT code, delta=2, abs
ORG 100h
;--------------------------------configuracion----------------------------------
main:
    bsf	    STATUS, 5
    bsf	    STATUS, 6
    clrf    ANSEL
    clrf    ANSELH
    
    bsf	    STATUS, 5
    bcf	    STATUS, 6
    clrf    TRISA
    
    bcf	    STATUS, 5
    bcf	    STATUS, 6
;***********loop proncipal************
loop:
    incf    PORTA, 1
    call    delay_big
    goto    loop
;***********subrutina de delay**********
delay_big:
    movlw   198
    movwf   cont_big
    call    delay_small
    decfsz  cont_big, 1
    goto    $-2
    return
    
delay_small:
    movlw   248
    movwf   cont_small
    decfsz  cont_small, 1
    goto    $-1
    return
end


