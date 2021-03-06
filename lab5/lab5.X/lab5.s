;Archivo:		lab5.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		Displays simultaneos
;Hardware:		Pushbuttons y transistores en el Puerto B, leds en el puerto A, display de 7seg de 2 digitos en el puerto C, y display de 7 seg
;
;Creado:		2 de marzo, 2021
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
    nibble:      DS 2	    ;guardar y separar los nibbles del puerto A
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
    call    config_io    ; RB0 y RB1 in y puertos A, C y D out
    call    config_iocb  ; configuracion del interrupt on change
    call    config_inten ; se configura el interrupt enable
    call    config_tmr0  ; se configura el tmr0
    bsf     banderas, 0  ; se inicializa el primer display
    
    
;****loop principal*****
loop:
    call    sepnibbles   ;se separan y almacenan los nibbles del byte del puerto A
    call    prepdisplays ;se preparan los displays del contador hexa
    clrf    cocientecen  ;se limpian las variables de calculo de las centenas, decenas y
    clrf    cocientedec  ;unidades
    clrf    numerador
    call    division     ;se efectua la division mediante resta
    goto    loop
;******subrutinas de interrupcion***********
int_ocb:
    banksel PORTA    ;se chequea cual de los dos pushbuttons fue presionado
    btfss   PORTB, 0 ;y se usa un antirebote
    incf    PORTA   ;
    btfss   PORTB, 1
    decf    PORTA
    bcf   RBIF    ;se resetea la bandera del interrupt on change
    return
int_tmr0:
    banksel PORTA     
    call  rst_tmr0   ;se resetea el tmr0
    clrf  PORTB      ;se limpia el puerto B (para los transistores)
    btfsc banderas, 0;se van chequeando cada una de las banderas para ver si se levantaron
    goto display1    ;y si no se han levantado entonces se enciende el display especifico
    btfsc banderas, 1
    goto display0
    btfsc banderas, 2
    goto display2
    btfsc banderas, 3
    goto display3
    btfsc banderas, 4
    goto display4
    

display0:
    movf  display_var+1, w  ;se enciende el display con la posicion mas significativa en hexa
    movwf PORTC
    bsf   PORTB, 2          ;se activa el transistor que enciende dicho display 
    bcf   banderas, 1       ;se apaga la bandera del display actual 
    bsf   banderas, 2       ;y se enciende la del siguiente display
    return
    
display1:
    movf  display_var, w    ;se enciende el display con la posicion menos significativa en hexa
    movwf PORTC
    bsf   PORTB, 3          ;se repite lo mismo que en el display0 pero para el display1
    bcf   banderas, 0
    bsf   banderas, 1
    return
    
display2:
    movf  dispcen, w        ;se enciende el display con la posicion de las centenas
    movwf PORTD             
    bsf   PORTB, 4
    bcf   banderas, 2       ;se repite lo mismo que en el display1 pero para el display2
    bsf   banderas, 3
    return
    
display3:
    movf  dispdec, w        ;se enciende el display con la posicion de las decenas
    movwf PORTD
    bsf   PORTB, 5
    bcf   banderas, 3       ;se repite lo mismo que en el display2 pero para el display3
    bsf   banderas, 4
    return

display4:
    movf  dispnum, w        ;se enciende el display con la posicion de las unidades
    movwf PORTD
    bsf   PORTB, 6
    bsf   banderas, 0       ;se repite lo mismo que en el display3 pero para el display4
    bcf   banderas, 4
    return

;los displays se encienden con las banderas asi: se apaga la bandera del display
;encendido actualmente y se enciende la bandera del siguiente display
;orden de los displays: 1, 0, 2, 3, 4
;---------------------subrutinas------------------------------------------------
sepnibbles:        ;se guardan ambas nibbles por separado en la variable nibble
    movf  PORTA, w ;se guarda la primera posición del hexa en nibble
    andlw 0x0f     ;se pone como tope la F (para numero hexa)
    movwf nibble   
    swapf PORTA, w ;y mediante un swap para nibble+1 (segunda posicion del hexa)
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
    return

division:                 ;operacion de division mediante resta
    bcf   STATUS, 0       ;se limpia la bandera de carry
    movf  PORTA, w        ;se mueve el numero binario del puerto A a la variable
    movwf numerador       ;numerador
    movlw 100             ;se mueve 100 al denominador 
    incf  cocientecen     ;se incrementa la variable de centenas
    subwf numerador, f    ;se resta 100 al numerador 
    btfsc STATUS, 0       ;se chequea la bandera de carry y si no se alteró entonces
    goto  $-3             ;se repite el procedimiento, hasta que la resta de un resultado <= 0
    decf  cocientecen     ;se decrementa la variable de centenas en 1
    addwf numerador       ;se suma 100 al numerador
    movf  cocientecen, w  ;se traduce el dato al display de 7segmentos y se mueve
    call  tabla           ;a la variable para encender el display de posición de centenas      
    movwf dispcen         
    bcf   STATUS, 0       ;se limpia la bandera de carry
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
    bcf     PS2   ; 001, que es 1:4
    bcf     PS1
    bsf     PS0
    banksel PORTA ;
    call    rst_tmr0; se resetea el timer0
    return
    
rst_tmr0:
    movlw 125     ;Valor calculado con la formula aprendida en clase
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

