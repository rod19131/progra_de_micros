;Archivo:		lab2.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		contador binario TMR0 ajustable con pushbuttons que despliegan el tiempo de reinicio en un 7 seg y una alarma de reinicio
;Hardware:		Pushbuttons en puerto B, Leds en el Puerto C, display 7 seg en puerto D y led en puerto E
;
;Creado:		16 febrero, 2021
;Ultima modificacion:	20 febrero, 2021
    
PROCESSOR 16F887
#include <xc.inc>

;CONFIGURATION WORD 1
CONFIG FOSC=INTRC_NOCLKOUT  ;Oscilador interno sin salida
CONFIG WDTE=OFF             ;Reinicio repetitivo del pic
CONFIG PWRTE=ON             ;espera de 72 ms al iniciar el pic
CONFIG MCLRE=OFF            ;El pin MCLR se utiliza como entrada/salida
CONFIG CP=OFF               ;Sin protección de código
CONFIG CPD=OFF              ;Sin protección de datos
    
CONFIG BOREN=OFF            ;Sin reinicio cuando el input voltage es inferior a 4V
CONFIG IESO=OFF             ;Reinicio sin cambio de reloj de interno a externo
CONFIG FCMEN=OFF            ;Cambio de reloj externo a interno en caso de fallas
CONFIG LVP=ON               ;Programación en low voltage permitida
    
;CONFIGURATION WORD 2
CONFIG WRT=OFF              ;Proteccion de autoescritura por el programa desactivada
CONFIG BOR4V=BOR40V         ;Reinicio abajo de 4V 
;**********variables a usar***********  
PSECT udata_shr ;memoria compartida
    
    sevseg:	; Variable para el 7 seg 
	DS 1
    
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
tabla:
    clrf    PCLATH
    bsf     PCLATH, 0   ; PCLATH = 01 y PCL = 02
    andlw   0x0F	; se pone como limite F, es decir que después de F vuelve a 0
    addwf   PCL         ; PCL = PCLATH + PCL + W
    retlw   00111111B	; 0
    retlw   00000110B	; 1
    retlw   01011011B	; 2
    retlw   01001111B	; 3
    retlw   01100110B	; 4
    retlw   01101101B	; 5
    retlw   01111101B	; 6
    retlw   00000111B	; 7
    retlw   01111111B	; 8
    retlw   01101111B	; 9
    retlw   01110111B	; A
    retlw   01111100B	; b
    retlw   00111001B	; C
    retlw   01011110B	; d
    retlw   01111001B	; E
    retlw   01110001B	; F 
main:
    call    config_reloj ; se configura el reloj
    call    config_io    ; se configuran las entradas y salidas de los pines
    call    config_tmr0  ; se configura el tmr0
    
    
;***********loop principal************
loop:
    ;Counter 1
    btfsc   PORTB, 0    ;Chequea la entrada del pin B0 (pushbutton de up1) y si es 0 (no se esta presionando) se salta la siguiente instruccion 
    call    inc_counter1;Llama a la funcion para subir el counter1
    btfsc   PORTB, 1    ;Chequea la entrada del pin B1 (pushbutton de down1) y si es 0 (no se esta presionando) se salta la siguiente instruccion   
    call    dec_counter1;LLama a la funcion para bajar el counter1
    btfss   T0IF        ;cuando se activa el Bit de bandera de overflow de tmr0, se salta la siguiente instruccion
    goto    $-5         ;regresa al inicio del loop cuando no hay overflow
    call    rst_tmr0    ;se llama a la funcion de reset del timer0
    incf    PORTC       ;se incrementa en 1 el puerto C (el contador binario de 4 bits)
    bcf     PORTC, 4    ;se ponen en 0 los bits sobrantes del puerto C
    bcf     PORTC, 5
    bcf     PORTC, 6
    bcf     PORTC, 7
    bcf	    PORTE, 0    ;se apaga el led de la alarma
    call    comp        ;se llama a la funcion de comparar para comprobar si el contador binario es igual al valor hexadecimal del 7seg
    goto    loop        ;regresa al inicio
;---------------------subrutinas------------------------------------------------    
config_reloj:
    banksel OSCCON; Seleccion de banco
    bcf     IRCF2 ; 001, Frecuencia de 125kHz
    bcf     IRCF1
    bsf     IRCF0
    bsf     SCS   ; reloj interno
    return

config_io:
    
    banksel ANSELH ;selecciona el banco donde se encuentra la seleccion  
    clrf    ANSELH ;de pines digitales 
    clrf    ANSEL  
    banksel TRISB  ;Seleccion del banco donde se encuentra TRISB (todos los TRIS están en ese banco)
    movlw   3h     ;Se pasa el dato en hexa a w para poner en 1 (entradas) 
    movwf   TRISB  ;los pines deseados en el puerto A (RA0, RA1, RA2, RA3 y RA4)
    clrf    TRISA  ;Se ponen los pines de los puertos B,C,D y E como salidas 
    clrf    TRISC 
    clrf    TRISD
    clrf    TRISE
    banksel PORTB  ;Se selecciona el banco que contiene el puerto B (y tambien contiene los demas puertos)
    clrf    PORTA  ;Se ponen todos los pines de los puertos A, C, D y E en 0 
    clrf    PORTC  
    clrf    PORTD
    clrf    PORTE
    bsf     PORTD, 0; inicio en 0
    bsf     PORTD, 1
    bsf     PORTD, 2
    bsf     PORTD, 3
    bsf     PORTD, 4
    bsf     PORTD, 5
    return

config_tmr0:
    banksel TRISA ;
    bcf     T0CS  ; reloj interno (low to high)
    bcf     PSA   ; prescaler
    bsf     PS2   ; 111, que es 1:256
    bsf     PS1
    bsf     PS0
    banksel PORTA ;
    call    rst_tmr0; se resetea el timer0
    return
    
rst_tmr0:
    movlw 195     ;Valor calculado con la formula aprendida en clase
    movwf TMR0    ;
    bcf   T0IF    ;se pone en cero la bandera de overflow del timer0
    return
    
;funcion de subir el counter1 en 1
inc_counter1:
    btfsc PORTB, 0 ;funciona como antirebote, se saltara la siguiente instruccion hasta que se suelte el pushbutton de subir counter1
    goto  $-1      ;regresa a la línea instruccion anterior
    incf  sevseg   ;sube la variable del 7segmentos en 1
    movf  sevseg, w;se pasa el valor de la variable a w
    call  tabla    ;se manda a llamar a la tabla para encender el valor indicado en el 7 segmentos
    movwf PORTD    ;se encienden los leds correspondientes del 7 segmentos en el puerto D
    return       
    
;funcion de bajar el counter1 en 1    
dec_counter1:
    btfsc   PORTB, 1 ;funciona como antirebote del boton bajar counter1 (solo salta la instruccion cuando se suelte)
    goto    $-1      ;regresa a la línea instruccion anterior
    decfsz  sevseg   ;baja la variable del 7segmentos en 1
    movf    sevseg, w;se pasa el valor de la variable a w
    call    tabla    ;se manda a llamar a la tabla para encender el valor indicado en el 7 segmentos
    movwf   PORTD    ;se encienden los leds correspondientes del 7 segmentos en el puerto D
    return 

comp:
    movf    PORTC,  w	; Se mueve el counter binario a W
    subwf   sevseg, w	; Se resta w a sevseg
    btfsc   STATUS, 2	; si la resta da 0 significa que son iguales entonces la zero flag se enciende
    call    alarma	; cuando la bandera de cero se activa se llama a alarma
    return
    
alarma:
    bsf	    PORTE, 0	; Encender led
    clrf    PORTC	; reinicio del 4 bit counter
    return
    
END






