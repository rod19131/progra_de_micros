/*
 * Archivo:     lab8.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Laboratorio7: LEDs y 7seg displays controlados por pots
 * Hardware:    2 pots y 3 transistores en puerto A, 8 LEDs en el puerto C y 
 *              7seg disps en PORTD
 * Creado:      19 de abril de 2021, 1:00 AM
 * Ultima modificacion: 19 de abril de 2021
 */
#define _XTAL_FREQ 500000
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
//arrays
//tabla 7 seg
unsigned char tabla[] = {0b00111111,//0
                         0b00000110,//1
                         0b01011011,//2
                         0b01001111,//3              
                         0b01100110,//4
                         0b01101101,//5
                         0b01111101,//6
                         0b00000111,//7
                         0b01111111,//8
                         0b01101111};//9

//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion del adc
    if (ADIF == 1) {
        PORTC = ADRESH;
        ADCON0bits.GO = 1;
        PIR1bits.ADIF = 0;
        //__delay_us(50);
    }
    //interrupcion del tmr0
    if (T0IF == 1) {
        cen = PORTC / 100;    //se obtienen las centenas al dividir c entre 100
        cenres = PORTC % 100; //se obtiene el residuo de la division entre 100
        dec = cenres / 10;//se obtienen las decenas al dividir el residuo entre 10
        uni = cenres % 10;//se obtienen las unidades al dividir el residuo entre 10
        TMR0 = 100;
        INTCONbits.T0IF = 0; //se baja la bandera de interrupcion del tmr0
        PORTBbits.RB2 = 0;
        PORTBbits.RB3 = 0;
        PORTBbits.RB4 = 0;
        PORTD = 0;
        //multiplexacion de los displays
        switch(dispvar) {
            case 0: 
                PORTAbits.RA4 = 1; //display 2 encendido
                PORTAbits.RA6 = 0;
                PORTAbits.RA7 = 0;
                PORTD = tabla[cen];//se traduce las centenas al display 2
                dispvar = 1; 
                break;
            case 1:
                PORTAbits.RA4 = 0;
                PORTAbits.RA6 = 1; //display 1 encendido
                PORTAbits.RA7 = 0;
                PORTD = tabla[dec];//se traduce las decenas al display 1
                dispvar = 2;      
                break;
            case 2:
                PORTAbits.RA4 = 0;
                PORTAbits.RA6 = 0;
                PORTAbits.RA7 = 1;  //display 0 encendido
                PORTD = tabla[uni]; //se traduce las unidades al display 0
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
    ANSELbits.ANS0  = 1;
    ANSELbits.ANS1  = 1;
    TRISA  = 15;
    TRISC  = 0;
    TRISD  = 0;
    PORTA  = 0;//se limpian los puertos
    PORTC  = 0;
    PORTD  = 0;
    //configuracion adc
    ADCON0bits.ADCS = 0;
    ADCON0bits.CHS0 = 0;
    ADCON0bits.ADON = 1;
    ADCON0bits.GO = 1;
    ADCON1bits.VCFG1 = 0;
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.ADFM = 0;
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
    INTCONbits.T0IE = 1; //interrupcion overflow tmr0 habilitada
    INTCONbits.PEIE = 1;
    PIE1bits.ADIE = 1;
    //PIR1bits.ADIF = 0;
    dispvar = 0;
    while (1)
    {if (ADCON0bits.GO == 0) {
        if(ADCON0bits.CHS == 0){
            PORTC = ADRESH;
            ADCON0bits.CHS = 1;
        }
        else{
            PORTD = ADRESH;
            ADCON0bits.CHS = 0;
        }
        __delay_us(50);
        ADCON0bits.GO = 1;
    }}
          
}
