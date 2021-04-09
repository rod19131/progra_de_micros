;Archivo:		proyecto1.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		Proyecto 1: Semaforos de 3 vias, con displays de 10 a 20
;                                   segundos y modo de configuración 
;
;Hardware:		8 displays 7seg en el puerto A, LEDs en el puerto C,E    
;                       transistores en el puerto D y LEDs y pushbuttons en 
;                       el puerto B
; 
;Creado:		21 de marzo, 2021
;Ultima modificacion:	6 de abril, 2021
    
PROCESSOR 16F887
#include <xc.inc>

;CONFIGURATION WORD 1
CONFIG FOSC=INTRC_NOCLKOUT;Oscilador interno sin salida
CONFIG WDTE=OFF           ;Reinicio repetitivo del pic
CONFIG PWRTE=ON           ;espera de 72 ms al iniciar el pic
CONFIG MCLRE=OFF          ;El pin MCLR se utiliza como entrada/salida
CONFIG CP=OFF             ;Sin protección de código
CONFIG CPD=OFF            ;Sin protección de datos
    
CONFIG BOREN=OFF          ;Sin reinicio cuando el input voltage es inferior a 4V
CONFIG IESO=OFF           ;Reinicio sin cambio de reloj de interno a externo
CONFIG FCMEN=OFF          ;Cambio de reloj externo a interno en caso de fallas
CONFIG LVP=ON             ;Programación en low voltage permitida
    
;CONFIGURATION WORD 2
CONFIG WRT=OFF          ;Proteccion de autoescritura por el programa desactivada
CONFIG BOR4V=BOR40V     ;Reinicio abajo de 4V 
;----------------------variables a usar----------------------------------------- 
PSECT udata_bank0      ;variable para:
    banderas:    DS 1  ;activar cada display
    bestados:    DS 1  ;boton presionado
    estadvar:    DS 1  ;identificar el modo actual 
    semaforo:    DS 1  ;variable temp para modificar el valor en verde del sem
    numerador:   DS 1  ;almacenar el valor de las unidades
    cocientedec: DS 1  ;almacenar el valor de las decenas
    dispconf0:   DS 1  ;dos displays de configuracion
    dispconf1:   DS 1  
    dispdecsem0: DS 1  ;decenas para display de cada via
    dispdecsem1: DS 1  
    dispdecsem2: DS 1  
    dispnumsem0: DS 1  ;unidades para display de cada via
    dispnumsem1: DS 1
    dispnumsem2: DS 1
    sem0:        DS 1  ;tiempo restante de cada semaforo
    sem1:        DS 1  
    sem2:        DS 1
    redsem0:     DS 1  ;tiempo de cada semaforo en rojo
    redsem1:     DS 1
    redsem2:     DS 1
    gresem0:     DS 1  ;tiempo de cada semaforo en verde
    gresem1:     DS 1
    gresem2:     DS 1
    config0:     DS 1  ;tiempo de configuracion de duracion de verde de cada 
    config1:     DS 1  ;semaforo
    config2:     DS 1  
    configmisc:  DS 1  ;comodin para guardar variable temporal de configuracion
    togglevar:   DS 1  ;toggle para intercambiar entre tiempo en verde y tiempo
    togglevar1:  DS 1  ;en rojo de cada semaforo
    togglevar2:  DS 1
    bandactual:  DS 1  ;para cargar los valores correctos luego de un reset
    contcomp:    DS 1  ;contador que se compara con el valor en verde del sem0
    yelsign:     DS 1  ;bandera para semaforos amarillos
    cont_big:    DS 1  ;variables para elaborar un delay de cerca de 1 s
    cont_small:  DS 1
    cont_mini:   DS 1
    titila:      DS 1  ;toggle para titileo cada 250 ms
    bandi:       DS 1  ;bandera para comenzar titileo cuando falten 6s en verde
PSECT udata_shr ;memoria compartida
    w_temp:      DS 1; variable para guardar w temporalmente
    s_temp:      DS 1; variable para guardar status temporalmente
    sevseg:      DS 1; Variable para el 7 seg del contador
    
;---------------instrucciones vector reset--------------------------------------   
PSECT resVect, class=CODE, abs, delta=2
;---------------------------------vector reset----------------------------------
ORG 00h
resetVec:
    PAGESEL main
    goto main
;----------------vector de interrupciones---------------------------------------
PSECT intVect, class = CODE, abs, delta = 2
ORG 04h
push:
    movwf w_temp    ;guardar w en una variable temporal
    swapf STATUS, w
    movwf s_temp

isr:
    btfsc RBIF      ;chequear la bandera de la interrupcion por cambio
    call  int_ocb   ;llama a la subrutina del boton
    btfsc T0IF      ;chequear la bandera de la interrupcion del tmr0 
    call  int_tmr0  ;llama a la subrutina del tmr0
    btfsc TMR1IF    ;chequear la bandera de la interrupcion del tmr1
    call  int_tmr1  ;llama a la suburutina del tmr1
    btfsc TMR2IF    ;chequear la bandera de la interrupcion del tmr2
    call  int_tmr2  ;llama a la subrutina de la interrupcion del tmr2

pop:
    swapf s_temp, w  ;regresar el w temporal a w 
    movwf STATUS     ;y regresar status temporal a status
    swapf w_temp, f
    swapf w_temp, w
    retfie

;---------------configuracion del micro-----------------------------------------    
PSECT code, delta=2, abs
ORG 100h
tabla: ;7 segmentos
    clrf    PCLATH
    bsf     PCLATH, 0   ; PCLATH = 01 y PCL = 02
    andlw   0x0F	; se pone como limite F
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
    call    config_reloj ;se configura el reloj
    call    config_io    ;RB0, RB1 y RB2 in y puertos A, C, D y E out
    call    config_iocb  ;configuracion del interrupt on change
    call    config_inten ;se configura el habilitador de interrupciones
    call    config_tmr0  ;se configura el tmr0
    call    config_tmr1  ;se configura el tmr1
    call    config_tmr2  ;se configura el tmr2
    bsf     banderas, 0  ;se inicializa el primer display
    movlw   10           ;se inicializan los tiempos de configuracion en verde
    movwf   config0      ;con un valor de 10s
    movwf   config1
    movwf   config2
    call    aceptar      ;se hace un reset
    movlw   0            ;se inicializa el toggle del semaforo 1 en 0 y los 
    movwf   togglevar    ;demas en 1
    movlw   1
    movwf   togglevar1
    movwf   togglevar2
    movwf   titila    
    clrf    bandi        ;se limpia la bandera de titileo
    
;---------------------------loop principal--------------------------------------
loop:
    btfsc   bestados, 0  ;se chequea si se presiono el boton de modo
    call    selestado
    call    modos        ;se chequea constantemente el modo en el que esta
    
    bcf     STATUS, 2    
    btfss   yelsign, 0   ;se compara el tiempo de semaforo0 cuando esta en verde
    goto    $+14         ;y cuando falten 6s levanta la bandera de titileo de 
    movlw   6            ;primer semaforo
    subwf   sem0, w   
    btfss   STATUS, 2	 
    goto    $+2
    bsf     bandi, 0
    
    bcf     STATUS, 2    ;se compara el tiempo de semaforo0 cuando esta en verde
    movlw   3            ;y cuando falten 3s se apaga el verde titilante y se 
    subwf   sem0, w      ;enciende el amarillo
    btfss   STATUS, 2	 
    goto    $+4
    bcf     bandi, 0
    bsf     PORTC, 1
    bcf     PORTC, 2
    
    bcf     STATUS, 2    ;se compara el tiempo de semaforo1 cuando esta en verde
    btfss   yelsign, 1   ;y cuando falten 6s levanta la bandera de titileo de 
    goto    $+14         ;segundo semaforo
    movlw   6            
    subwf   sem1, w   
    btfss   STATUS, 2	  
    goto    $+2
    bsf     bandi, 1

    bcf     STATUS, 2    ;se compara el tiempo de semaforo1 cuando esta en verde
    movlw   3            ;y cuando falten 3s se apaga el verde titilante y se  
    subwf   sem1, w      ;enciende el amarillo
    btfss   STATUS, 2	  
    goto    $+4   
    bcf     bandi, 1
    bsf     PORTC, 4
    bcf     PORTC, 5
    
    bcf     STATUS, 2    ;se compara el tiempo de semaforo2 cuando esta en verde
    btfss   yelsign, 2   ;y cuando falten 6s levanta la bandera de titileo de 
    goto    $+14         ;tercer semaforo
    movlw   6             
    subwf   sem2, w   
    btfss   STATUS, 2	   
    goto    $+2
    bsf     bandi, 2
    
    bcf     STATUS, 2    ;se compara el tiempo de semaforo1 cuando esta en verde
    movlw   3            ;y cuando falten 3s se apaga el verde titilante y se 
    subwf   sem2, w      ;enciende el amarillo
    btfss   STATUS, 2	   
    goto    $+4  
    bcf     bandi, 2
    bsf     PORTC, 7
    bcf     PORTE, 0
    goto    loop
;-------------------subrutinas de interrupcion----------------------------------
 
;subrutina de interrupcion de boton presionado    
int_ocb:
    banksel PORTB
    btfss   PORTB, 0   ;antirebote boton modos
    bsf     bestados, 0
    btfss   PORTB, 1   ;antirebote boton subir
    bsf     bestados, 1
    btfss   PORTB, 2   ;antirebote boton bajar
    bsf     bestados, 2
    bcf     RBIF       ;limpieza de bandera de interrupt on change
    return

;subrutina de interrupcion de tmr0  (ocurre cada 10ms)
int_tmr0:
    banksel PORTA     
    call  rst_tmr0   ;se resetea el tmr0
    clrf  PORTD      ;se limpia el puerto D (para los transistores)
    btfsc banderas, 0;se van chequeando cada una de las banderas y si no se han
    goto display0    ; levantado entonces se enciende el display especifico
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
    
;los displays se encienden con las banderas asi: se apaga la bandera del display
;encendido actualmente y se enciende la bandera del siguiente display
    
;display de decenas de configuracion
display0:
    movf  dispconf1, w  ;se enciende el disp de decenas de config 
    movwf PORTA
    bsf   PORTD, 0      ;se activa el transistor que enciende dicho display 
    bcf   banderas, 0   ;se apaga la bandera del display actual 
    bsf   banderas, 1   ;y se enciende la del siguiente display
    return
    
;display de unidades de configuracion    
display1:
    movf  dispconf0, w  ;se enciende el disp de unidades de config
    movwf PORTA
    bsf   PORTD, 1      ;se activa el transistor que enciende dicho display 
    bcf   banderas, 1   ;se apaga la bandera del display actual 
    bsf   banderas, 2   ;y se enciende la del siguiente display
    return
 
;display de decenas de semaforo0    
display2:
    movf  dispdecsem0, w ;se enciende el disp de decenas 0
    movwf PORTA             
    bsf   PORTD, 2       ;se activa el transistor que enciende dicho display 
    bcf   banderas, 2    ;se apaga la bandera del display actual       
    bsf   banderas, 3    ;y se enciende la del siguiente display
    return

;display de unidades de semaforo0    
display3:
    movf  dispnumsem0, w  ;se enciende el disp de unidades 0
    movwf PORTA
    bsf   PORTD, 3
    bcf   banderas, 3   ;se repite lo mismo que en el disp2 para encender disp3
    bsf   banderas, 4
    return

;display de decenas de semaforo1    
display4:
    movf  dispdecsem1, w ;se enciende el disp de decenas 1
    movwf PORTA
    bsf   PORTD, 4
    bcf   banderas, 4    ;se repite lo mismo que en el disp3 pero para el disp4
    bsf   banderas, 5
    return

;display de unidades de semaforo1    
display5:
    movf  dispnumsem1, w ;se enciende el disp de unidades 1
    movwf PORTA
    bsf   PORTD, 5
    bcf   banderas, 5    ;se repite lo mismo que en el disp4 pero para el disp5
    bsf   banderas, 6
    return

;display de decenas de semaforo2    
display6:
    movf  dispdecsem2, w ;se enciende el disp de decenas 2
    movwf PORTA
    bsf   PORTD, 6
    bcf   banderas, 6    ;se repite lo mismo que en el disp5 pero para el disp6
    bsf   banderas, 7
    return

;display de unidades de semaforo2    
display7:
    movf  dispnumsem2, w ;se enciende el display con la posicion de las unidades
    movwf PORTA
    bsf   PORTD, 7
    bcf   banderas, 7    ;se repite lo mismo que en el disp6 pero para el disp7
    bsf   banderas, 0
    return

;subrutina de interrupcion del tmr1 (ocurre cada 1s)
int_tmr1:
    banksel PORTA        
    call    rst_tmr1
    
    ;actualizacion del semaforo0 
    decf    sem0      ;se decrementa en 1 segundo el valor actual del semaforo0
    
    bcf     STATUS, 2 ;se compara el valor actual del semaforo0 y si es igual a 
    movlw   0         ;0 entonces se carga el valor del siguiente tiempo    
    subwf   sem0 , w  ;(oscila entre tiempo en verde y tiempo en rojo cada
    btfss   STATUS, 2 ;underflow  
    goto    $+7
    incf    togglevar    ;toggle del semaforo0 (ocurre cada underflow)
    btfsc   togglevar, 0 ;si el primer toggle es 1 el primer semaforo pasa a
    call    luzroja0     ;estado en rojo
    btfss   togglevar, 0 ;si el primer toggle es 0 el primer semaforo pasa a 
    call    luzverde0    ;estado en verde
    movwf   sem0         ;dependiendo del primer toggle se carga un valor verde 
                         ;o rojo al semaforo0
			 
    ;actualizacion del semaforo1
    decf    sem1      ;se decrementa en 1 segundo el valor actual del semaforo1
    
    bcf     STATUS, 2 ;se repite el procedimiento del semaforo0 pero para el
    movlw   0         ;semaforo1  usando la segunda variable de toggle   
    subwf   sem1 , w   
    btfss   STATUS, 2
    goto    $+7   
    incf    togglevar1
    btfsc   togglevar1, 0
    call    luzroja1
    btfss   togglevar1, 0
    call    luzverde1
    movwf   sem1

    ;actualizacion del semaforo2
    decf    sem2      ;funciona igual que el semaforo1 y semaforo0
    bcf     STATUS, 2
    movlw   0            
    subwf   sem2 , w   
    btfss   STATUS, 2	   
    goto    $+7   
    incf    togglevar2
    btfsc   togglevar2, 0
    call    luzroja2
    btfss   togglevar2, 0
    call    luzverde2
    movwf   sem2
    
    ;primera corrida luego de aceptar cambios
    bcf     STATUS, 2    
    btfss   bandactual, 0 ;se chequea la bandera de la primera corrida 
    goto    $+11
    movf    gresem0, w    ;se compara el tiempo en verde con un contador
    subwf   contcomp, w   ;que comienza luego de aceptar cambios
    btfss   STATUS, 2     
    goto    $+3
    incf    contcomp      ;se incrementa contador
    goto    $+5           
    movf    gresem0, w    ;se actualiza el valor en rojo1 para el funcionamiento
    addwf   gresem2, w    ;general del semaforo luego de la primera corrida
    movwf   redsem1       ;luego de aceptar cambios
    bcf     bandactual, 0 ;se limpia la bandera de la primera corrida
    return

;modo rojo semaforo0    
luzroja0:
    movf    redsem0, w  ;se actualiza w con el valor en rojo del semaforo0
    bsf     PORTC, 0    ;se enciende el rojo
    bcf     PORTC, 1    ;se apaga el amarillo
    bcf     PORTC, 2    ;se apaga el verde   
    bcf     yelsign, 0  ;se apaga la bandera de que el semaforo0 esta en verde
    return
     
luzroja1:      
    movf    redsem1, w ;se actualiza w con el valor en rojo del semaforo1 
    bsf     PORTC, 3   ;se enciende el rojo
    bcf     PORTC, 4   ;se apaga el amarillo
    bcf     PORTC, 5   ;se apaga el verde 
    bcf     yelsign, 1 ;se apaga la bandera de que el semaforo1 esta en verde
    return
    
luzroja2:
    movf    redsem2, w ;se actualiza w con el valor en rojo del semaforo2
    bsf     PORTC, 6   ;se enciende el rojo
    bcf     PORTC, 7   ;se apaga el amarillo
    bcf     PORTE, 0   ;se apaga el verde 
    bcf     yelsign, 2 ;se apaga la bandera de que el semaforo2 esta en verde
    return
    
luzverde0:
    movf    gresem0, w ;se actualiza w con el valor en verde del semaforo0
    bcf     PORTC, 0   ;se enciende el rojo
    bcf     PORTC, 1   ;se apaga el amarillo
    bsf     PORTC, 2   ;se apaga el verde 
    bsf     yelsign, 0 ;se enciende la bandera de que el semaforo0 esta en verde
    return

luzverde1:
    movf    gresem1, w ;se actualiza w con el valor en verde del semaforo1
    bcf     PORTC, 3   ;se enciende el rojo
    bcf     PORTC, 4   ;se apaga el amarillo
    bsf     PORTC, 5   ;se apaga el verde 
    bsf     yelsign, 1 ;se enciende la bandera de que el semaforo1 esta en verde
    return
    
luzverde2:
    movf    gresem2, w ;se actualiza w con el valor en verde del semaforo1
    bcf     PORTC, 6   ;se enciende el rojo
    bcf     PORTC, 7   ;se apaga el amarillo
    bsf     PORTE, 0   ;se apaga el verde
    bsf     yelsign, 2 ;se enciende la bandera de que el semaforo2 esta en verde
    return

;Interrupcion del timer 2 (cada 250ms)
int_tmr2:
    banksel PIR1 
    incf    titila   ;se incrementa el puerto D cada 250 ms (toggle cada 250ms)
    btfss   bandi, 0 ;se chequea la bandera de titileo de semaforo0
    goto    $+2
    goto    titi0    ;titileo de verde en semaforo0
    btfss   bandi, 1 ;se chequea la bandera de titileo de semaforo1
    goto    $+2
    goto    titi1    ;titileo de verde en semaforo1
    btfss   bandi, 2 ;se chequea la bandera de titileo de semaforo2
    goto    $+2
    goto    titi2    ;titileo de verde en semaforo2
    bcf     TMR2IF   ;se limpia la bandera de interrupcion del timer 2
    return

    
titi0:
    btfsc titila, 0 ;se chequea el toggle de titileo y si es 0 se apaga el sem0
    goto  vertiti0  ;si es 1 se enciende el led
    bcf   PORTC, 2  ;se apaga el verde
    bcf   TMR2IF    ;se limpia la bandera de interrupcion del timer 2
    return

titi1:
    btfsc titila, 0 ;funciona igual que titi0 pero para el semaforo1
    goto  vertiti1
    bcf   PORTC, 5
    bcf   TMR2IF
    return

titi2:
    btfsc titila, 0 ;funciona igual que titi0 pero para el semaforo2
    goto  vertiti2
    bcf   PORTE, 0
    bcf   TMR2IF
    return
    
vertiti0:
    bsf    PORTC, 2 ;se enciende el verde0
    bcf    TMR2IF   ;limpia bandera de interrupcion de tmr2
    return
    
vertiti1:
    bsf    PORTC, 5 ;se enciende el verde1
    bcf    TMR2IF   ;limpia bandera de interrupcion de tmr2
    return

vertiti2:
    bsf    PORTE, 0 ;se enciende el verde2
    bcf    TMR2IF   ;limpia bandera de interrupcion de tmr2
    return
    
;---------------------subrutinas------------------------------------------------
selestado:
    banksel PORTA
    incf    estadvar   ;si se presiono el boton de modo se incrementa la bandera
    bcf     STATUS, 2  ;de modo y se loopea de 0 a 4  
    movlw   5           
    subwf   estadvar, w 
    btfss   STATUS, 2	
    goto    $+3   
    movlw   0   	
    movwf   estadvar
    bcf     bestados, 0; se limpia la bandera del boton modos
    return

subir: 
    banksel PORTA
    incf    semaforo     ;se incrementa bandera temporal de semaforo en config
    bcf     STATUS, 2    ;se compara si es igual a 21 entonces se hace 
    movlw   21           ;overflow y loopea a 10
    subwf   semaforo , w   
    btfss   STATUS, 2	   
    goto    $+3   
    movlw   10   	   
    movwf   semaforo
    bcf     bestados, 1  ;se limpia la bandera de boton subir
    return
 
bajar: 
    banksel PORTA
    decf    semaforo      ;se incrementa bandera temporal de semaforo en config
    bcf     STATUS, 2     ;se compara si es igual a 9 entonces se hace underflow
    movlw   9             ;y loopea a 20
    subwf   semaforo , w   
    btfss   STATUS, 2	   
    goto    $+3   
    movlw   20   	   
    movwf   semaforo
    bcf     bestados, 2
    return
    
division:                 ;operacion de division mediante resta
    clrf  cocientedec  ;unidades
    clrf  numerador
    bcf   STATUS, 0       ;se limpia la bandera de carry
    movwf numerador       ;numerador
    movlw 10              ;se mueve 10 al denominador 
    incf  cocientedec     ;se incrementa la variable de decenas 
    subwf numerador, f    ;se resta 10 al numerador
    btfsc STATUS, 0       ;se chequea la bandera de carry y si no se alteró entonces
    goto  $-3             ;se repite el procedimiento hasta que la resta de un resultado <= 0
    decf  cocientedec     ;se decrementa la variable de decenas en 1
    addwf numerador       ;se suma 10 al numerador
    return

modos:
    banksel PORTA       ;se va comparando (mediante bandera cero)la variable de 
    bcf     STATUS, 2   ;estadvar que indica el modo y dependiendo del numero en 
    movlw   0           ;que esta entonces se va al modo correspondiente
    subwf   estadvar, w
    btfsc   STATUS, 2
    call    modo_0      ;modo funcionamiento normal 
    bcf     STATUS, 2   
    movlw   1
    subwf   estadvar, w
    btfsc   STATUS, 2
    call    modo_1      ;modo configuracion del semaforo0
    bcf     STATUS, 2
    movlw   2
    subwf   estadvar, w
    btfsc   STATUS, 2
    call    modo_2      ;modo configuracion del semaforo1
    bcf     STATUS, 2
    movlw   3
    subwf   estadvar, w
    btfsc   STATUS, 2
    call    modo_3      ;modo configuracion del semaforo2
    bcf     STATUS, 2
    movlw   4
    subwf   estadvar, w
    btfsc   STATUS, 2
    call    modo_4      ;modo aceptar o cancelar cambios
    return

modoperm:
    movf  sem0, w         ;se mueve el tiempo actual del semaforo0 para 
    call  division        ;pasarlo a decimal
    movf  cocientedec, w  ;se traduce el dato al display de 7segmentos 
    call  tabla           ;la variable  para encender el display de decenas
    movwf dispdecsem0         
    movf  numerador, w    ;se traduce el dato del numerador restante al display 
    call  tabla           ;la variable para encender el display de unidades
    movwf dispnumsem0
    movf  sem1, w         ;se mueve el tiempo actual del semaforo1 para 
    call  division        ;pasarlo a decimal
    movf  cocientedec, w  ;se traduce el dato del numerador restante al display  
    call  tabla           ;la variable  para encender el display de decenas
    movwf dispdecsem1         
    movf  numerador, w    ;se traduce el dato del numerador restante al display
    call  tabla           ;la variable para encender el display de unidades
    movwf dispnumsem1
    movf  sem2, w         ;se mueve el tiempo actual del semaforo2 para 
    call  division        ;pasarlo a decimal
    movf  cocientedec, w  ;se traduce el dato del numerador restante al display  
    call  tabla           ;la variable  para encender el display de decenas
    movwf dispdecsem2         
    movf  numerador, w    ;se traduce el dato del numerador restante al display
    call  tabla           ;la variable para encender el display de unidades
    movwf dispnumsem2
    return

;modo generalizado para subir o bajar    
modoconfig: 
    movwf   semaforo      ;se mueve w a la variable temporal de semaforo
    btfsc   bestados, 1   ;dependiendo si se presiono subir o bajar, se llama 
    call    subir         ;a la subrutina correspondiente para aumentar o 
    btfsc   bestados, 2   ;decrementar la variable de configuracion
    call    bajar
    movf    semaforo, w
    movwf   configmisc     ;variable temporal de configuracion
    call    division       ;se pasa a decimal
    movf    cocientedec, w ;se traduce el dato del numerador restante al display
    call    tabla          ;la variable  para encender el display de decenas
    movwf   dispconf1         
    movf    numerador, w   ;se traduce el dato del numerador restante al display
    call    tabla          ;la variable para encender el display de unidades
    movwf   dispconf0
    call    modoperm      ;se llama al modo de funcionamiento normal de semaforo
    return
    
    
;funcionamiento normal    
modo_0:
    bcf  PORTB, 3 ;se apagan los leds indicadores de via en configuracion
    bcf  PORTB, 4
    bcf  PORTB, 5
    bcf  bestados, 1 ;se limpia la bandera de botones de subir o bajar
    bcf  bestados, 2
    clrf dispconf1   ;se apaga el display e configuracion
    clrf dispconf0
    call modoperm    ;los semaforos siguen funcionando normalmente
    return
   
;primera via en configuracion    
modo_1:
    bsf     PORTB, 3      ;se enciende el led de primera via en configuracion
    movf    config0, w    ;se mueve la variable de config0 de semaforo0 a w
    call    modoconfig    ;se usa el modo de configuracion general
    movf    configmisc, w ;se actualiza el valor de la variable de config0
    movwf   config0       ;de semaforo0
    return
   
;segunda via en configuracion    
modo_2:
    bcf     PORTB, 3      ;se apaga led de primera via en configuracion
    bsf     PORTB, 4      ;se enciende led de segunda via en configuracion
    movf    config1, w    ;se realiza el mismo procedimento que para el
    call    modoconfig    ;semaforo0 pero para el semaforo1
    movf    configmisc, w
    movwf   config1
    return
    
;tercera via en configuracion   
modo_3:
    bcf     PORTB, 3      ;se apaga led de primera via en configuracion
    bcf     PORTB, 4      ;se apaga led de segunda via en configuracion
    bsf     PORTB, 5      ;se enciende led de tercera via en configuracion
    movf    config2, w    ;se realiza el mismo procedimento que para el
    call    modoconfig    ;semaforo1 pero para el semaforo2
    movf    configmisc, w
    movwf   config2
    return

;modo aceptar o cancelar cambios        
modo_4:
    bsf   PORTB, 3      ;se encienden todos los leds de via en configuracion
    bsf   PORTB, 4
    movlw 01110111B	; A
    movwf dispconf1 
    movlw 0111001B	; C
    movwf dispconf0
    call  modoperm      ;los semaforos siguen funcionando normal
    btfsc bestados, 1   ;si se presiona aceptar se llama una secuencia de 
    goto  aceptar       ;reseteo con los nuevos valores
    btfsc bestados, 2   ;si se presiona cancelar se borran los valores de 
    goto  cancelar      ;configuracion no aplicados
    return              ;que se habian elegido y se regresan a 0

;secuencia de aceptar
aceptar:
    movlw   0111110B    ;se mueven valores para desplegarse en los displays 
    movwf   dispconf0   ;U
    movwf   dispconf1   ;U
    movlw   1111011B    ;palabra: reset
    movwf   dispnumsem0 
    movwf   dispnumsem1 
    movlw   0000001B    
    movwf   dispnumsem2
    movlw   0110001B
    movwf   dispdecsem0
    movlw   1101101B
    movwf   dispdecsem1
    movlw   0000111B
    movwf   dispdecsem2
    call    luzroja0    ;se ponen todos los semaforos en rojo
    call    luzroja1
    call    luzroja2
    clrf    bandi       ;se limpia la bandera de titileo
    call    delay_big   ;se llama un delay de 1.5s aproximadamente
    call    luzverde0   ;se pone el primer semaforo en verde
    bsf   bandactual, 0 ;se activa la bandera de reseteo (para primera corrida)
    movf  config0, w    ;se mueve el valor de config0 elegido para verde en el 
    movwf gresem0       ;semaforo0
    movwf sem0          ;se mueve el valor al semaforo0 rojo 
    movwf redsem1       ;se carga el valor de semaforo0 a semaforo1 actual
    movwf sem1          ;y semaforo1 rojo(solo primera corrida)
    movf  config1, w    ;se mueve el valor de config1 elegido para verde en el
    movwf gresem1       ;semaforo1
    movf  config2, w    ;se mueve el valor de config2 elegido para verde en el
    movwf gresem2       ;semaforo2
    movf  gresem1, w    ;se suma el valor del semaforo1 en verde con el 
    addwf gresem2, w    ;semaforo2 en verde para obtener el tiempo del semaforo0
    movwf redsem0       ;en rojo
    movf  gresem0, w    ;se suma el valor del semaforo0 en verde con el 
    addwf gresem1, w    ;semaforo1 en verde para obtener el tiempo en el 
    movwf redsem2       ;semaforo2 en rojo
    movwf sem2          ;se mueve el valor al semaforo2 actual
    movlw 0             ;se pone la variable de modo en 0 para modo normal
    movwf estadvar
    movlw 10            ;se ponen los valores de configuracion en 10 por defecto
    movwf config0
    movwf config1
    movwf config2
    bcf     PORTC, 0    ;se pone en verde el primer semaforo
    bcf     PORTC, 1
    bsf     PORTC, 2
    bsf     yelsign, 0  ;se enciende la bandera de que el semaforo0 es verde
    bsf     PORTC, 3    ;se pone en rojo el segundo semaforo
    bcf     PORTC, 4    
    bcf     PORTC, 5   
    bcf     yelsign, 1  ;se enciende la bandera de que el semaforo1 es verde
    bsf     PORTC, 6    ;se pone en rojo el tercera semaforo
    bcf     PORTC, 7
    bcf     PORTE, 0
    bcf     yelsign, 2  ;se enciende la bandera de que el semaforo2 es verde
    movlw   0           ;se pone en cero el toggle del semaforo0
    movwf   togglevar
    movlw   1           ;se pone en uno el toggle del semaforo1 o semaforo2
    movwf   togglevar1  
    movwf   togglevar2
    return

;cancelar cambios    
cancelar:
    movlw 10      ;se ponen en 0 las variables de configuracion (para editar)
    movwf config0 ;de los tres semaforos (se descartan cambios)
    movwf config1
    movwf config2
    movlw 0       ;se regresa al modo 0
    movwf estadvar
    return

;delay del reseteo 1 s aprox    
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
    call    delay_mini
    decfsz  cont_small, 1
    goto    $-1
    return

delay_mini:
    movlw   200
    movwf   cont_mini
    decfsz  cont_mini, 1
    goto    $-1
    return

;----------------configuraciones de funciones del micro-------------------------  
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
    banksel TRISB  ;Seleccion del banco donde se encuentra TRISB 
    movlw   7h     ;Se pasa el dato en hexa a w para poner en 1 (entradas) 
    movwf   TRISB  ;los pines deseados en el puerto B como in(RB0, RB1)
    clrf    TRISA  ;Se ponen los pines de los puertos A,C,D y E como salidas 
    clrf    TRISC  
    clrf    TRISD 
    clrf    TRISE
    bcf     OPTION_REG, 7 ;habilitar los pull ups
    bsf     WPUB, 0 ;habilitar los pullups en RB0 y RB1 como inputs
    bsf     WPUB, 1
    bsf     WPUB, 2
    banksel PORTB  ;Se selecciona el banco que contiene el puerto B 
    clrf    PORTA  ;Se ponen todos los pines de los puertos A,B,C y D en 0 
    bcf     PORTB, 3
    bcf     PORTB, 4
    bcf     PORTB, 5
    clrf    PORTC  
    clrf    PORTD
    clrf    PORTE
    return

config_iocb:
    banksel TRISA  ;se configuran los pines de  RB0, RB1 y RB2 con int on change
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
    banksel PIR1
    movlw   11011100B;valor para que se resetee cada segundo
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
    bsf     TMR2IE ;habilita la interrupcion del tmr2
    return

END