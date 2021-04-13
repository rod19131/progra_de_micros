/*
 * Archivo:     lab7.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Laboratorio7: Contador con PB, Contador con tmr0, 3 disp decimal
 * Hardware:    2 PB y transistores en el PORTB, LEDs en PORTA, LEDs en PORTC,
 *              7seg disps en PORTD
 * Creado:      12 de abril de 2021, 10:19 PM
 * Ultima modificacion: 12 de abril de 2021
 */

#include <xc.h>
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
unsigned char c;       //contador de botones
unsigned char cen;     //centenas
unsigned char dec;     //decenas
unsigned char uni;     //unidades
unsigned char cenres;  //residuo de centenas
unsigned char dispvar; //multiplexado

//tabla 7 segmentos
unsigned char tabla(unsigned char valor){
    switch(valor) {
            //0
            case 0:
                return 0b00111111;
                break;
            //1
            case 1:
                return 0b00000110;
                break;
            //2
            case 2:
                return 0b01011011;
                break;
            //3
            case 3:
                return 0b01001111;
                break;   
            //4
            case 4:
                return 0b01100110;
                break; 
            //5
            case 5:
                return 0b01101101;
                break;
            //6
            case 6:
                return 0b01111101;
                break;
            //7
            case 7:
                return 0b00000111;
                break;
            //8
            case 8:
                return 0b01111111;
                break;
            //9
            case 9:
                return 0b01101111;
                break;
        }
}
//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion por cambio (boton)
    if(RBIF == 1)  {
        //incremento de la variable con antirebote
        if (PORTBbits.RB0 == 0) {
            c++; 
        }
        //decremento de la variable con antirebote
        if (PORTBbits.RB1 == 0) {
            c--; 
        }
        //se baja la bandera de interrupcion por cambio
        INTCONbits.RBIF = 0;
    }
    //interrupcion del tmr0
    if (T0IF == 1) {
        //incremento del puerto C cada 5 ms
        PORTC++;
        TMR0 = 100;
        INTCONbits.T0IF = 0; //se baja la bandera de interrupcion del tmr0
        PORTBbits.RB2 = 0;
        PORTBbits.RB3 = 0;
        PORTBbits.RB4 = 0;
        PORTD = 0;
        //multiplexacion de los displays
        switch(dispvar) {
            case 0: 
                PORTBbits.RB2 = 1; //display 2 encendido
                PORTBbits.RB3 = 0;
                PORTBbits.RB4 = 0;
                PORTD = tabla(cen);//se traduce las centenas al display 2
                dispvar = 1; 
                break;
            case 1:
                PORTBbits.RB2 = 0;
                PORTBbits.RB3 = 1; //display 1 encendido
                PORTBbits.RB4 = 0;
                PORTD = tabla(dec);//se traduce las decenas al display 1
                dispvar = 2;      
                break;
            case 2:
                PORTBbits.RB2 = 0;
                PORTBbits.RB3 = 0;
                PORTBbits.RB4 = 1;  //display 0 encendido
                PORTD = tabla(uni); //se traduce las unidades al display 0
                dispvar = 0; 
                break;
        }
    }    
  
}

void main(void) {
    //configuraciones
    //configuracion reloj
    OSCCONbits.IRCF2 = 1;//001, Frecuencia de reloj 1 MHz
    OSCCONbits.IRCF1 = 0;
    OSCCONbits.IRCF0 = 0;
    OSCCONbits.SCS   = 1;//reloj interno
    //configuracion in out
    ANSELH = 0; //Pines digitales
    ANSEL  = 0;
    TRISB  = 3;//Se pone como input RB0 y RB1 y todos los demas pines como out
    TRISA  = 0;
    TRISC  = 0;
    TRISD  = 0;
    OPTION_REGbits.nRBPU = 0; //pullups habilitados
    WPUBbits.WPUB0 = 1;       //pullups RB0 y RB1 
    WPUBbits.WPUB1 = 1;
    PORTA  = 0;               //se limpian los puertos
    PORTB  = 0;
    PORTC  = 0;
    PORTD  = 0;
    //configuracion interrupt on change b
    IOCBbits.IOCB0 = 1; //Se habilita la interrupcion por cambio en RB0 y RB1
    IOCBbits.IOCB1 = 1;
    //configuracion tmr0
    OPTION_REGbits.T0CS = 0; //reloj interno (low to high)
    OPTION_REGbits.PSA  = 0; //prescaler 
    OPTION_REGbits.PS2  = 0; //011, 1:8
    OPTION_REGbits.PS1  = 1;
    OPTION_REGbits.PS0  = 1;
    //reset tmr0
    TMR0 = 100; //para que el tmr0 se reinicie cada 5 ms
    INTCONbits.T0IF = 0; //baja la bandera de interrupcion del tmr0
    //configuracion interrupciones
    INTCONbits.GIE  = 1; //se habilitan las interrupciones globales
    INTCONbits.RBIE = 1; //interrupcion on change habilitada
    INTCONbits.T0IE = 1; //interrupcion overflow tmr0 habilitada
    dispvar = 0;
    while (1)
    {PORTA = c;        //se pasa la variable de contador al puerto A
     cen = c / 100;    //se obtienen las centenas al dividir c entre 100
     cenres = c % 100; //se obtiene el residuo de la division entre 100
     dec = cenres / 10;//se obtienen las decenas al dividir el residuo entre 10
     uni = cenres % 10;//se obtienen las unidades al dividir el residuo entre 10
     }
          
}

