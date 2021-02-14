;Archivo:		lab2.S
;Dispositivo:		PIC16F887
;Autor;			Jose Alejandro Rodriguez Porras
;Compilador:		pic-as (v2.31) MPLABX V5.40
;
;Programa:		Contador en el Puerto A
;Hardware:		Leds en el Puerto A
;
;Creado:		9 febrero, 2021
;Ultima modificación:	9 febrero, 2021
    
PROCESSOR 16F887
#include <xc.inc>

;CONFIGURATION WORD 1
CONFIG FOSC=XT  ;Oscilador externo
CONFIG WDTE=OFF ;Reinicio repetitivo del pic
CONFIG PWRTE=ON ;espera de 72 ms al iniciar el pic
CONFIG MCLRE=OFF;El pin MCLR se utiliza como entrada/salida
CONFIG CP=OFF   ;Sin protección de código
CONFIG CPD=OFF  ;Sin protección de datos
    
CONFIG BOREN=OFF;Sin reinicio cuando el input voltage es inferior a 4V
CONFIG IESO=OFF ;Reinicio sin cambio de reloj de interno a externo
CONFIG FCMEN=OFF;Cambio de reloj externo a interno en caso de fallas
CONFIG LVP=ON   ;Programación en low voltage permitida
    
;CONFIGURATION WORD 2
CONFIG WRT=OFF      ;Protección de autoescritura por el programa desactivada
CONFIG BOR4V=BOR40V ;Reinicio abajo de 4V 
;**********variables a usar***********    
; no se usaron variables
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
    banksel ANSELH ;selecciona el banco donde se encuentra la seleccion  
    clrf    ANSELH ;de pines digitales 
    clrf    ANSEL  
    banksel TRISA  ;Seleccion del banco donde se encuentra TRISA (todos los TRIS están en ese banco)
    movlw   1Fh    ;Se pasa el dato en hexa a w para poner en 1 (entradas) 
    movwf   TRISA  ;los pines deseados en el puerto A (RA0, RA1, RA2, RA3 y RA4)
    clrf    TRISB  ;Se ponen los pines de los puertos B,C y D como salidas 
    clrf    TRISC 
    clrf    TRISD
    banksel PORTB  ;Se selecciona el banco que contiene el puerto B (y tambien contiene los demas puertos)
    clrf    PORTB  ;Se ponen todos los pines de los puertos B, C y D en 0 
    clrf    PORTC  
    clrf    PORTD
;***********loop principal************
loop:
    ;Counter 1
    btfsc   PORTA, 0    ;Chequea la entrada del pin A0 (pushbutton de up1) y si es 0 (no se esta presionando) se salta la siguiente instruccion 
    call    inc_counter1;Llama a la funcion para subir el counter1
    btfsc   PORTA, 1    ;Chequea la entrada del pin A1 (pushbutton de down1) y si es 0 (no se esta presionando) se salta la siguiente instruccion   
    call    dec_counter1;LLama a la funcion para bajar el counter1
    ;Counter 2
    btfsc   PORTA, 2    ;Chequea la entrada del pin A2 (pushbutton de up2) y si es 0 (no se esta presionando) se salta la siguiente instruccion 
    call    inc_counter2;Llama a la funcion para subir el counter2
    btfsc   PORTA, 3    ;Chequea la entrada del pin A3 (pushbutton de down2) y si es 0 (no se esta presionando) se salta la siguiente instruccion
    call    dec_counter2;Llama a la funcion para bajar el counter2
    ;Suma
    btfsc   PORTA, 4    ;Chequea la entrada del pin A0 (pushbutton de sumcounters) y si es 0 (no se esta presionando) se salta la siguiente instruccion
    call    sumcounters ;Se llama a la funcion de sumar el counter1 con el counter2
    goto    loop
    
;***********subrutinas*********
;funcion de subir el counter1 en 1
inc_counter1:
    btfsc PORTA, 0 ;funciona como antirebote, se saltara la siguiente instruccion hasta que se suelte el pushbutton de subir counter1
    goto  $-1      ;regresa a la línea instruccion anterior
    incf  PORTB, 1 ;sube el counter1
    return       
    
;funcion de bajar el counter1 en 1    
dec_counter1:
    btfsc PORTA, 1 ;funciona como antirebote del boton bajar counter1 (solo salta la instruccion cuando se suelte)
    goto  $-1      ;regresa a la línea instruccion anterior
    decf  PORTB, 1 ;baja el counter1
    return 
    
;funcion de subir el counter2 en 1    
inc_counter2:
    btfsc PORTA, 2 ;funciona como antirebote del boton subir counter2 (solo salta la instruccion cuando se suelte)
    goto  $-1      ;regresa a la línea instruccion anterior
    incf  PORTC, 1 ;sube el counter2
    return    
    
;funcion de bajar el counter2 en 1
dec_counter2:
    btfsc PORTA, 3 ;funciona como antirebote del boton bajar counter2 (solo salta la instruccion cuando se suelte)
    goto  $-1      ;regresa a la línea instruccion anterior
    decf  PORTC, 1 ;baja el counter2
    return    

;funcion de sumar el counter1 con el counter2 y desplegar el resultado
sumcounters:
    btfsc PORTA, 4 ;funciona como antirebote del boton bajar counter2 (solo salta la instruccion cuando se suelte) 
    goto  $-1      ;regresa a la línea instruccion anterior
    bcf   PORTB, 4 ;se ponen los bits que están demás en 0 en los puertos B y C (para solo tomar los 4 bits menos significativos)
    bcf   PORTB, 5
    bcf   PORTB, 6
    bcf   PORTB, 7
    bcf   PORTC, 4
    bcf   PORTC, 5
    bcf   PORTC, 6
    bcf   PORTC, 7
    movf  PORTB, w ;mueve el dato en los pines del puerto b a w
    addwf PORTC, w ;suma w con el dato f en los pines del puerto C, y actualiza w con el resultado
    movwf PORTD    ;pasa w a los pines del puerto D
    return  
END


