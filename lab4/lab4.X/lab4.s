;Archivo:		lab4.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		
;Hardware:		Pushbuttons en puerto B, Leds en Puerto A, 7seg en puerto C y 7seg en puerto D
;
;Creado:		22 febrero, 2021
;Ultima modificacion:	27 febrero, 2021
    
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
    w_temp:    DS 1; variable para guardar w temporalmente
    s_temp:    DS 1; variable para guardar status temporalmente
    sevseg:    DS 1; Variable para el 7 seg del contador
    sevsegtmr: DS 1; Variable para el 7 seg del timer0
    
;*********instrucciones vector reset**********   
PSECT resVect, class=CODE, abs, delta=2
;---------------------------------vector reset----------------------------------
ORG 00h
resetVec:
    PAGESEL main
    goto main
;*********vector de interrupciones**********
PSECT intVect, class = CODE, abs, delta = 2
ORG 04h
push:
    movwf w_temp    ;guardar w en una variable temporal
    swapf STATUS, w
    movwf s_temp

isr:
    btfsc RBIF      ;chequear la bandera de la interrupcion por cambio
    call  int_ocb
    btfsc T0IF
    call  int_tmr

pop:
    swapf s_temp, w  ;regresar el w temporal a w 
    movwf STATUS     ;y regresar status temporal a status
    swapf w_temp, f
    swapf w_temp, w
    retfie
    
;**********configuracion del micro**********    
PSECT code, delta=2, abs
ORG 100h
tabla: ;7 segmentos
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
    call    config_io    ; RB0 y RB1 in y puertos A, C y D out
    call    config_iocb  ; configuracion del interrupt on change
    call    config_inten ; se configura el interrupt enable
    call    config_tmr0  ; se configura el tmr0
    
    
;***********loop principal************
loop:
    movf    sevseg,w    ;se mueve del dato de la variable sevseg a w
    movwf   PORTA       ;se pasa w al puerto A
    call    tabla	;se llama a la tabla para encender el 7 segmentos del puerto C
    movwf   PORTC	;con la conversion de valores del puerto A en hexa
    goto    loop
;---------------------subrutinas------------------------------------------------    
int_ocb:
    banksel PORTA    ;se chequea cual de los dos pushbuttons fue presionado
    btfss   PORTB, 0 ;y se usa un antirebote
    incf    sevseg   ;
    btfss   PORTB, 1
    decf    sevseg
    bcf   RBIF    ;se resetea la bandera del interrupt on change
    return
 
int_tmr:
    call    rst_tmr0		; Regresa la bandera de overflow del tmr0 a 0
    incf    sevsegtmr           ;se incrementa la variable del 7seg del tmr 0 cada 
    movf    sevsegtmr, w        ;segundo
    call    tabla
    movwf   PORTD
    return
    
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
    movwf   TRISB  ;los pines deseados en el puerto B como in(RB0, RB1)
    clrf    TRISA  ;Se ponen los pines de los puertos A,C,D y E como salidas 
    clrf    TRISC  
    clrf    TRISD 
    bcf     OPTION_REG, 7 ;habilitar los pull ups
    bsf     WPUB, 0 ;habilitar los pullups en RB0 y RB1 como inputs
    bsf     WPUB, 1
    banksel PORTB  ;Se selecciona el banco que contiene el puerto B (y tambien contiene los demas puertos)
    clrf    PORTA  ;Se ponen todos los pines de los puertos A, C, D y E en 0 
    clrf    PORTC  
    clrf    PORTD
    return

config_iocb:
    banksel TRISA    ;se configuran los pines de  RB0 y RB1 con interrupcion en cambio
    bsf     IOCB, 0  ;interrupt on change para reaccionar con los pb
    bsf     IOCB, 1
    banksel PORTA
    movf    PORTB, w 
    bcf     RBIF     ;se pone en 0 la bandera de la interrupcion por cambio
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
    movlw 134     ;Valor calculado con la formula aprendida en clase
    movwf TMR0    ;
    bcf   T0IF    ;se pone en cero la bandera de overflow del timer0
    return
    
config_inten:
    bsf     GIE  ;enable global de interrupts
    bsf     RBIE ;interrupt on change habilitado
    bcf     RBIF ;pone en 0 la bandera del interrupt on change
    bsf     T0IE ;habilita interrupt de overflow del tmr0
    return
    
END


