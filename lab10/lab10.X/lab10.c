/*
 * Archivo:     lab10.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Laboratorio10: Comunicacion serial
 * Hardware:    LEDs en puerto A y B, Terminal en puerto C (RX y TX)
 * Creado:      3 de mayo de 2021, 9:15 PM
 * Ultima modificacion: 3 de mayo de 2021
 */
#define _XTAL_FREQ 1000000 //frecuencia de 1 MHz
#include <xc.h>
#include <stdint.h>
//palabra de configuracion 1
#pragma config FOSC=INTRC_NOCLKOUT //Oscilador interno sin salida
#pragma config WDTE=OFF           //Reinicio repetitivo del pic
#pragma config PWRTE=ON           //espera de 72 ms al iniciar el pic
#pragma config MCLRE=OFF          //El pin MCLR se utiliza como entrada/salida
#pragma config CP=OFF             //Sin protección de código
#pragma config CPD=OFF            //Sin protección de datos
    
#pragma config BOREN=OFF //Sin reinicio cuando el input voltage es inferior a 4V
#pragma config IESO=OFF  //Reinicio sin cambio de reloj de interno a externo
#pragma config FCMEN=OFF //Cambio de reloj externo a interno en caso de fallas
#pragma config LVP=ON    //Programación en low voltage permitida
    
//CONFIGURATION WORD 2
#pragma config WRT=OFF //Proteccion de autoescritura por el programa desactivada
#pragma config BOR4V=BOR40V //Reinicio abajo de 4V 
//variables
unsigned char dato = 103;
//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion de recepcion
    if (PIR1bits.RCIF) {
        PORTB = RCREG; //caracter a puertob
    }   
}

void main(void) {
    //configuraciones
    //configuracion reloj
    OSCCONbits.IRCF = 0b100;//100, Frecuencia de reloj 1 MHz
    OSCCONbits.SCS   = 1;//reloj interno
    //configuracion in out
    ANSELH = 0; //Pines digitales
    ANSEL = 0;
    TRISA  = 0; //RA0 y RA1 como inputs y los demas como outputs
    TRISB = 0;
    PORTA = 0;//se limpian los puertos
    PORTB = 0;
    //configuracion de TX y RX
    TXSTAbits.SYNC = 0;    //asincrono
    TXSTAbits.BRGH = 1;    //highspeed
    BAUDCTLbits.BRG16 = 1; //16 bits baud rate
    SPBRG = 25;            
    SPBRGH = 0;            
    RCSTAbits.SPEN = 1;    //modulo USART encendido
    RCSTAbits.RX9 = 0;     //no 9 bits
    RCSTAbits.CREN = 1;    //recepcion
    TXSTAbits.TXEN = 1;    //transmision
    //configuracion interrupciones
    PIR1bits.RCIF = 0;    //bandera recepcion apagada
    PIE1bits.RCIE = 1;    //enable bandera recepcion
    
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;   //se habilitan las interrupciones por adc
    INTCONbits.PEIE = 1; //se habilitan las interrupciones de los perifericos
    INTCONbits.GIE  = 1; //se habilitan las interrupciones globales
    while (1){
    __delay_ms(500);
    if (PIR1bits.TXIF)
    {TXREG = dato;}}//se pasa el caracter a la terminal      
}