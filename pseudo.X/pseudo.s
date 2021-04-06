;Archivo:		lab6.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:              Temporizadores tmr1 y tmr2 para aumentar variable cada seg
;                       y LED y 7 seg intermitentes con timer2
;
;Hardware:		2 displays 7seg y 1 LED en el puerto A,transistores en   
;                       el puerto D
; 
;Creado:		23 de marzo, 2021
;Ultima modificacion:	25 de marzo, 2021
    
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
    cuenta:      DS 1       ;variable de aumento
    nibble:      DS 2
    display_var: DS 2       ;almacenar la conversion a display hexa de los nibbles
    titila:      DS 1
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
    btfsc T0IF      ;chequear la bandera de la interrupción del tmr0 
    call  int_tmr0  ;llama a la subrutina del tmr0
    btfsc TMR1IF    ;chequear la bandera de la interrupción del tmr1
    call  int_tmr1  ;llamar a la subrutina del tmr1
    btfsc TMR2IF    ;chequear la bandera de la interrupción del tmr2
    call  int_tmr2  ;llamar a la subrutina del tmr2

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
    call    config_inten ; se configura el interrupt enable
    call    config_tmr0  ; se configura el tmr0
    call    config_tmr1  ; se configura el tmr1
    call    config_tmr2  ; se configura el tmr2
    bsf     banderas, 0  ; se inicializa el primer display
    
;****loop principal*****
loop:
    call    sepnibbles   ;se separan y almacenan los nibbles del byte de la variable cuenta
    call    prepdisplays ;se preparan los displays del contador hexa
    goto    loop
;******subrutinas de interrupcion***********
    
int_tmr0:
    banksel PORTA     
    call  rst_tmr0       ;se resetea el tmr0
    clrf  PORTA          ;se limpia el puerto C (para los transistores)
    btfss PORTD, 0       ;se chequea el pin del led intermitente y si esta apagado
    goto  displayapagado ;se apaga el display
    btfsc banderas, 0    ;se van chequeando cada una de las banderas para ver si se levantaron
    goto display0        ;y si no se han levantado entonces se enciende el display especifico
    btfsc banderas, 1
    goto display1

;los displays se encienden con las banderas asi: se apaga la bandera del display
;encendido actualmente y se enciende la bandera del siguiente display
    
display0:
    movf  display_var+1, w  ;se enciende el display con la posicion mas significativa en hexa
    movwf PORTA
    bsf   PORTC, 0          ;se activa el transistor que enciende dicho display 
    bcf   banderas, 0       ;se apaga la bandera del display actual 
    bsf   banderas, 1       ;y se enciende la del siguiente display
    return
    
display1:
    movf  display_var, w    ;se enciende el display con la posicion menos significativa en hexa
    movwf PORTA
    bsf   PORTC, 1          ;se repite lo mismo que en el display0 pero para el display1
    bcf   banderas, 1   
    bsf   banderas, 0
    return

displayapagado:
    clrf PORTA ;se apaga el display de acuerdo al led intermitente
    return

int_tmr1:
    banksel PORTA
    call    rst_tmr1 ;se resetea el tmr1 cada segundo y se aumenta en 1 la 
    incf    cuenta   ;variable
    return
 
;int_tmr2:
;    banksel PIR1   
;    incf    PORTD   ;se incrementa el puerto D cada 250 ms, lo que ocasiona que
;    bcf     TMR2IF  ;el bit menos significativo (donde se conecta el LED) se cambie cada int
;    return
int_tmr2:
    banksel PIR1   
    incf    titila   ;se incrementa el puerto D cada 250 ms, lo que ocasiona que
    ;btfss   yelsign, 0
    btfsc   titila, 0
    goto    amatiti0
    bcf     PORTE, 1     
    bcf     TMR2IF  ;el bit menos significativo (donde se conecta el LED) se cambie cada int
    return

amatiti0:
    bsf    PORTE, 1
    bcf    TMR2IF
    return
;---------------------subrutinas------------------------------------------------
sepnibbles:        ;se guardan ambas nibbles por separado en la variable nibble
    movf  cuenta, w ;se guarda la primera posición del hexa en nibble
    andlw 0x0f     ;se pone como tope la F (para numero hexa)
    movwf nibble   
    swapf cuenta, w ;y mediante un swap para nibble+1 (segunda posicion del hexa)
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
    banksel TRISA  ;Seleccion del banco donde se encuentra TRISA (todos los TRIS están en ese banco)
    clrf    TRISA  ;Se ponen los pines de los puertos A y C como salidas 
    clrf    TRISC  
    clrf    TRISD
    clrf    TRISE
    banksel PORTA  ;Se selecciona el banco que contiene el puerto A (y tambien contiene los demas puertos)
    clrf    PORTA  ;Se ponen todos los pines de los puertos A y C en 0 
    clrf    PORTC
    clrf    PORTD
    clrf    PORTE
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

config_tmr2:
    banksel T2CON
    bsf     TMR2ON  ;Encender el tmr2
    bsf     TOUTPS3 ;Configuración de postscaler 1:16
    bsf     TOUTPS2 ;1111
    bsf     TOUTPS1 ;
    bsf     TOUTPS0 ;Configuración de prescaler 1:16 
    bsf     T2CKPS1 ;1x
    banksel TRISA   
    movlw   244     ;número calculado para pasar a PR2 y que se obtenga 
    movwf   PR2     ;250 ms
    banksel PORTA
    bcf     TMR2IF  ;se limpia la bandera de interrupción del tmr2
    return
    
rst_tmr0:
    movlw 125     ;Valor calculado con la formula aprendida en clase
    movwf TMR0    ;
    bcf   T0IF    ;se pone en cero la bandera de overflow del timer0
    return

rst_tmr1:
    banksel PIR1      ;valor para que exista un overflow cada segundo 
    movlw   11011100B ;8 bits menos significativos para el registro de tmr1
    movwf   TMR1L
    movlw   1011B     ;8 bits más significativos para el registro de tmr1
    movwf   TMR1H
    bcf     TMR1IF    ;se limpia la bandera de overflow de tmr1
    return
    
config_inten:
    bsf     GIE    ;enable global de interrupts
    bsf     T0IE   ;habilita interrupt de overflow del tmr0
    bcf     TMR1IF ;pone en 0 la bandera de interrupcion de overflow de tmr1
    bsf     TMR1IE ;habilita la interrupcion del overflow del tmr1
    bsf     PEIE   ;habilita unmasked interrupts (para tmr1)
    bsf     TMR2IE ;habilita la interrupcion del tmr2
    return
    
END


