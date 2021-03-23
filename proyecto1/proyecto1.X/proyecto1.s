;Archivo:		proyecto1.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		Proyecto 1: Semaforos de 3 vias, con displays de 10 a 20
;                                   segundos y modo de configuración 
;
;Hardware:		8 displays 7seg en el puerto A, LEDs en el puerto C,    
;                       transistores en el puerto D y LEDs y pushbuttons en 
;                       el puerto B
; 
;Creado:		21 de marzo, 2021
;Ultima modificacion:	6 de marzo, 2021
    
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
;***variables a usar**** 
PSECT udata_bank0           ;variable para:
    banderas:    DS 1       ;activar cada display
    dispvar:     DS 2
    bestados:    DS 1
    estadvar:    DS 1
    semaforo:    DS 1
    display_var: DS 2       ;almacenar la conversion a display hexa de los nibbles
    numerador:   DS 1       ;almacenar el valor de las unidades
    cocientecen: DS 1       ;almacenar el valor de las centenas
    cocientedec: DS 1       ;almacenar el valor de las decenas
    dispcen:     DS 1       ;guardar el valor de centena traducido por la tabla 
    dispdec:     DS 1       ;guardar el valor de decena traducido por la tabla
    dispnum:     DS 1       ;guardar el valor de unidad traducido por la tabla
    
PSECT udata_shr ;memoria compartida
    w_temp:    DS 1; variable para guardar w temporalmente
    s_temp:    DS 1; variable para guardar status temporalmente
    sevseg:    DS 1; Variable para el 7 seg del contador
;****instrucciones vector reset***   
PSECT resVect, class=CODE, abs, delta=2
;---------------------------------vector reset----------------------------------
ORG 00h
resetVec:
    PAGESEL main
    goto main
;****vector de interrupciones***
PSECT intVect, class = CODE, abs, delta = 2
ORG 04h
push:
    movwf w_temp    ;guardar w en una variable temporal
    swapf STATUS, w
    movwf s_temp

isr:
    btfsc RBIF      ;chequear la bandera de la interrupcion por cambio
    call  int_ocb   ;llama a la subrutina del boton
    btfsc T0IF      ;chequear la bandera de la interrupción del tmr0 
    call  int_tmr0  ;llama a la subrutina del tmr0
    btfsc TMR1IF    
    call  int_tmr1

pop:
    swapf s_temp, w  ;regresar el w temporal a w 
    movwf STATUS     ;y regresar status temporal a status
    swapf w_temp, f
    swapf w_temp, w
    retfie

;***configuracion del micro***    
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
    call    config_io    ; RB0, RB1 y RB2 in y puertos A, C y D out
    call    config_iocb  ; configuracion del interrupt on change
    call    config_inten ; se configura el interrupt enable
    call    config_tmr0  ; se configura el tmr0
    call    config_tmr1  ; se configura el tmr1
    bsf     banderas, 0  ; se inicializa el primer display
    movlw   10
    movwf   semaforo
    
    
;****loop principal*****
loop:
    ;se limpian las variables de calculo de las centenas, decenas y
    clrf    cocientedec  ;unidades
    clrf    numerador
    call    division     ;se efectua la division mediante resta
    btfsc   bestados, 0
    call    selestado
    btfsc   bestados, 1
    call    subir
    btfsc   bestados, 2
    call    bajar
    goto    loop
;******subrutinas de interrupcion***********
 
int_ocb:
    banksel PORTB
    btfss   PORTB, 0
    bsf     bestados, 0
    btfss   PORTB, 1
    bsf     bestados, 1
    btfss   PORTB, 2
    bsf     bestados, 2
    bcf     RBIF
    return
    
    
    
/*int_ocb:
    banksel PORTA    ;se chequea cual de los dos pushbuttons fue presionado
    btfss   PORTB, 1 ;y se usa un antirebote
    incf    dispvar   ;
    btfss   PORTB, 2
    decf    dispvar
    bcf   RBIF    ;se resetea la bandera del interrupt on change
    return*/
int_tmr0:
    banksel PORTA     
    call  rst_tmr0   ;se resetea el tmr0
    clrf  PORTA      ;se limpia el puerto D (para los transistores)
    btfsc banderas, 0;se van chequeando cada una de las banderas para ver si se levantaron
    goto display0    ;y si no se han levantado entonces se enciende el display especifico
    btfsc banderas, 1
    goto display1
    btfsc banderas, 2
    goto display2
    btfsc banderas, 3
    goto display3
    btfsc banderas, 4
    goto display4
    btfsc banderas, 5
    goto display5
    btfsc banderas, 6
    goto display6
    btfsc banderas, 7
    goto display7

display0:
    movf  dispdec, w  ;se enciende el display con la posicion mas significativa en hexa
    movwf PORTA
    bsf   PORTD, 0          ;se activa el transistor que enciende dicho display 
    bcf   banderas, 0       ;se apaga la bandera del display actual 
    bsf   banderas, 1       ;y se enciende la del siguiente display
    return
    
display1:
    movf  dispnum, w    ;se enciende el display con la posicion menos significativa en hexa
    movwf PORTA
    bsf   PORTD, 1          ;se repite lo mismo que en el display0 pero para el display1
    bcf   banderas, 1
    bsf   banderas, 2
    return
    
display2:
    movf  dispdec, w        ;se enciende el display con la posicion de las centenas
    movwf PORTA             
    bsf   PORTD, 2
    bcf   banderas, 2       ;se repite lo mismo que en el display1 pero para el display2
    bsf   banderas, 3
    return
    
display3:
    movf  dispnum, w        ;se enciende el display con la posicion de las decenas
    movwf PORTA
    bsf   PORTD, 3
    bcf   banderas, 3       ;se repite lo mismo que en el display2 pero para el display3
    bsf   banderas, 4
    return

display4:
    movf  dispdec, w        ;se enciende el display con la posicion de las unidades
    movwf PORTA
    bsf   PORTD, 4
    bcf   banderas, 4       ;se repite lo mismo que en el display3 pero para el display4
    bsf   banderas, 5
    return

display5:
    movf  dispnum, w        ;se enciende el display con la posicion de las unidades
    movwf PORTA
    bsf   PORTD, 5
    bcf   banderas, 5       ;se repite lo mismo que en el display3 pero para el display4
    bsf   banderas, 6
    return

display6:
    movf  dispdec, w        ;se enciende el display con la posicion de las unidades
    movwf PORTA
    bsf   PORTD, 6
    bcf   banderas, 6       ;se repite lo mismo que en el display3 pero para el display4
    bsf   banderas, 7
    return

display7:
    movf  dispnum, w        ;se enciende el display con la posicion de las unidades
    movwf PORTA
    bsf   PORTD, 7
    bcf   banderas, 7       ;se repite lo mismo que en el display3 pero para el display4
    bsf   banderas, 0
    return

int_tmr1:
    banksel PORTA
    call    rst_tmr1
    incf    semaforo
    bcf     STATUS, 2
    movlw   21             ; Se mueve el 20 a W
    subwf   semaforo , w   ; Se resta w a sevseg
    btfss   STATUS, 2	   ; si la resta da 0 significa que son iguales entonces la zero flag se enciende
    goto    $+3   
    movlw   10   	   ; cuando la bandera de cero se activa se llama a alarma
    movwf   semaforo
    bcf     bestados, 1
    return
;los displays se encienden con las banderas asi: se apaga la bandera del display
;encendido actualmente y se enciende la bandera del siguiente display
;orden de los displays: 1, 0, 2, 3, 4
;---------------------subrutinas------------------------------------------------
/*sepnibbles:        ;se guardan ambas nibbles por separado en la variable nibble
    movf  dispvar, w ;se guarda la primera posición del hexa en nibble
    andlw 0x0f     ;se pone como tope la F (para numero hexa)
    movwf nibble   
    swapf dispvar, w ;y mediante un swap para nibble+1 (segunda posicion del hexa)
    andlw 0x0f     ;
    movwf nibble+1
    return
prepdisplays:         ;se pasan nibble y nibble+1 a la traduccion de la tabla
                      ;en hexa y se guardan en la variable de display_var y display_var+1
    movf  nibble, w   ;traduccion del primero digito hexa llamando a la tabla
    call  tabla
    movwf display_var ;se guarda en display_var
    movf  nibble+1, w ;se repite el proceso para traduccion del segundo digito hexa 
    call  tabla       ;a display_var+1
    movwf display_var+1
    return*/
selestado:
    banksel PORTA
    incf    estadvar
    bcf     STATUS, 2
    movlw   5           ; Se mueve el 20 a W
    subwf   estadvar, w ; Se resta w a sevseg
    btfss   STATUS, 2	; si la resta da 0 significa que son iguales entonces la zero flag se enciende
    goto    $+3   
    movlw   0   	; cuando la bandera de cero se activa se llama a alarma
    movwf   estadvar
    bcf     bestados, 0
    return

subir: 
    banksel PORTA
    incf    semaforo
    bcf     STATUS, 2
    movlw   21             ; Se mueve el 20 a W
    subwf   semaforo , w   ; Se resta w a sevseg
    btfss   STATUS, 2	   ; si la resta da 0 significa que son iguales entonces la zero flag se enciende
    goto    $+3   
    movlw   10   	   ; cuando la bandera de cero se activa se llama a alarma
    movwf   semaforo
    bcf     bestados, 1
    return
 
bajar: 
    banksel PORTA
    decf    semaforo
    bcf     STATUS, 2
    movlw   9              ; Se mueve el 20 a W
    subwf   semaforo , w   ; Se resta w a sevseg
    btfss   STATUS, 2	   ; si la resta da 0 significa que son iguales entonces la zero flag se enciende
    goto    $+3   
    movlw   20   	   ; cuando la bandera de cero se activa se llama a alarma
    movwf   semaforo
    bcf     bestados, 2
    return
    
division:                 ;operacion de division mediante resta
    bcf   STATUS, 0       ;se limpia la bandera de carry
    movf  semaforo, w     ;se mueve el numero binario del puerto A a la variable
    movwf numerador       ;numerador
    movlw 10              ;se mueve 10 al denominador 
    incf  cocientedec     ;se incrementa la variable de decenas 
    subwf numerador, f    ;se resta 10 al numerador
    btfsc STATUS, 0       ;se chequea la bandera de carry y si no se alteró entonces
    goto  $-3             ;se repite el procedimiento hasta que la resta de un resultado <= 0
    decf  cocientedec     ;se decrementa la variable de decenas en 1
    addwf numerador       ;se suma 10 al numerador
    movf  cocientedec, w  ;se traduce el dato al display de 7segmentos y se mueve a 
    call  tabla           ;la variable  para encender el display de posición de decenas
    movwf dispdec         
    movf  numerador, w    ;se traduce el dato del numerador restante al display de 7segmentos
    call  tabla           ;y se mueve a la variable para encender el display de posición de unidades
    movwf dispnum
    return
    
config_reloj:
    banksel OSCCON; Seleccion de banco
    bsf     IRCF2 ; 001, Frecuencia de 1MHz
    bcf     IRCF1
    bcf     IRCF0
    bsf     SCS   ; reloj interno
    return

config_io: 
    banksel ANSELH ;selecciona el banco donde se encuentra la seleccion  
    clrf    ANSELH ;de pines digitales 
    clrf    ANSEL  
    banksel TRISB  ;Seleccion del banco donde se encuentra TRISB (todos los TRIS están en ese banco)
    movlw   7h     ;Se pasa el dato en hexa a w para poner en 1 (entradas) 
    movwf   TRISB  ;los pines deseados en el puerto B como in(RB0, RB1)
    clrf    TRISA  ;Se ponen los pines de los puertos A,C,D y E como salidas 
    clrf    TRISC  
    clrf    TRISD 
    bcf     OPTION_REG, 7 ;habilitar los pull ups
    bsf     WPUB, 0 ;habilitar los pullups en RB0 y RB1 como inputs
    bsf     WPUB, 1
    bsf     WPUB, 2
    banksel PORTB  ;Se selecciona el banco que contiene el puerto B (y tambien contiene los demas puertos)
    clrf    PORTA  ;Se ponen todos los pines de los puertos A,B,C y D en 0 
    bcf     PORTB, 3
    bcf     PORTB, 4
    bcf     PORTB, 5
    clrf    PORTC  
    clrf    PORTD
    return

config_iocb:
    banksel TRISA    ;se configuran los pines de  RB0, RB1 y RB2 con interrupcion en cambio
    bsf     IOCB, 0  ;interrupt on change para reaccionar con los pb
    bsf     IOCB, 1
    bsf     IOCB, 2
    banksel PORTA
    movf    PORTB, w 
    bcf     RBIF     ;se pone en 0 la bandera de la interrupcion por cambio
    return
    
config_tmr0:
    banksel TRISA 
    bcf     T0CS  ; reloj interno (low to high)
    bcf     PSA   ; prescaler
    bcf     PS2   ; 001, que es 1:4
    bcf     PS1
    bsf     PS0
    banksel PORTA 
    call    rst_tmr0; se resetea el timer0
    return

config_tmr1:
    banksel T1CON
    bsf     T1CKPS1 ;Prescaler de 1:4
    bcf     T1CKPS0 ;10
    bcf     TMR1CS  ;Reloj interno
    bsf     TMR1ON  ;timer1 habilitado
    call    rst_tmr1
    return    
    
rst_tmr0:
    movlw 125     ;Valor calculado con la formula aprendida en clase
    movwf TMR0    ;
    bcf   T0IF    ;se pone en cero la bandera de overflow del timer0
    return

rst_tmr1:
    banksel PIR1
    movlw   11011100B
    movwf   TMR1L
    movlw   1011B
    movwf   TMR1H
    bcf     TMR1IF
    return
    
config_inten:
    bsf     GIE    ;enable global de interrupts
    bsf     RBIE   ;interrupt on change habilitado
    bcf     RBIF   ;pone en 0 la bandera del interrupt on change
    bsf     T0IE   ;habilita interrupt de overflow del tmr0
    bcf     TMR1IF ;pone en 0 la bandera de interrupcion de overflow de tmr1
    bsf     TMR1IE ;habilita la interrupcion del overflow del tmr1
    bsf     PEIE   ;habilita unmasked interrupts (para tmr1)
    return
    
END


