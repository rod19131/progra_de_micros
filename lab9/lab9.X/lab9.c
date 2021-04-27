/*
 * Archivo:     lab9.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Laboratorio9: Servos con pots (modulo PWM1 y 2)
 * Hardware:    2 pots en puerto A y 2 servos en CCP1 y CCP2
 * Creado:      25 de abril de 2021, 10:25 AM
 * Ultima modificacion: 26 de abril de 2021
 */
#define _XTAL_FREQ 8000000 //frecuencia de 8 MHz
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
//124
//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion del adc
    if (ADIF == 1) {
        //multiplexacion de canales para el adc
        //canal LEDs
        if(ADCON0bits.CHS == 0){
            CCPR1L = (ADRESH>>1)+124;//para que el servo1 pueda girar 180 grados
            CCP1CONbits.DC1B1 = ADRESH & 0b01; //añadir precision/resolucion
            CCP1CONbits.DC1B0 = (ADRESL>>7);
            ADCON0bits.CHS = 1; //se cambia al canal del segundo pot
        }
        //canal displays
        else{
            CCPR2L = (ADRESH>>1)+124;//para que el servo0 pueda girar 180 grados
            CCP2CONbits.DC2B1 = ADRESH & 0b01;//añadir precision/resolucion
            CCP2CONbits.DC2B0 = (ADRESL>>7);
            ADCON0bits.CHS = 0;//se cambia a canal del primer pot
        }
        __delay_us(50);   //delay de 50 us
        PIR1bits.ADIF = 0;//interrupcion de adc
        ADCON0bits.GO = 1;//inicio de la siguiente conversión
    }
}

void main(void) {
    //configuraciones
    //configuracion reloj
    OSCCONbits.IRCF = 0b0111;//0111, Frecuencia de reloj 8 MHz
    OSCCONbits.SCS   = 1;//reloj interno
    //configuracion in out
    ANSELH = 0; //Pines digitales
    ANSELbits.ANS0  = 1;//RA0 y RA1 como pines analogicos
    ANSELbits.ANS1  = 1;
    TRISA  = 3; //RA0 y RA1 como inputs y los demas como outputs
    TRISC  = 0;
    PORTA  = 0;//se limpian los puertos
    PORTC  = 0;
    //configuracion adc
    ADCON0bits.ADCS = 2;//10 se selecciona Fosc/32 para conversion 4us full TAD
    ADCON0bits.CHS0 = 0;//se selecciona el canal AN0
    ADCON1bits.VCFG1 = 0;//se ponen los voltajes de referencia internos del PIC
    ADCON1bits.VCFG0 = 0;//0V a 5V
    ADCON1bits.ADFM = 0; //se justifica a la izquierda, vals más significativos
    ADCON0bits.ADON = 1;//se enciende el adc
    __delay_us(50);   //delay de 50 us
    //configuracion pwm
    //ccp1
    TRISCbits.TRISC2 = 1;      //CCP1 como entrada;
    PR2 = 250;                 //valor para que el periodo pwm sea 2 ms 
    CCP1CONbits.P1M = 0;       //config pwm
    CCP1CONbits.CCP1M = 0b1100;
    CCPR1L = 0x0f;             //ciclo de trabajo inicial
    CCP1CONbits.DC1B = 0;
    //ccp2
    TRISCbits.TRISC1 = 1;      //CCP2 como entrada;
    CCP2CONbits.CCP2M = 0b1100;//config pwm
    CCPR2L = 0x0f;             //ciclo de trabajo inicial
    CCP2CONbits.DC2B1 = 0;
    //configuracion tmr2
    PIR1bits.TMR2IF = 0; //se apaga la bandera de interrupcion del tmr2
    T2CONbits.T2CKPS = 0b11;//prescaler 1:16
    T2CONbits.TMR2ON = 1;//se enciende el tmr2
    while(PIR1bits.TMR2IF == 0);//esperar un ciclo de tmr2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;//out pwm2
    TRISCbits.TRISC1 = 0;//out pwm1
    //configuracion interrupciones
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;   //se habilitan las interrupciones por adc
    INTCONbits.PEIE = 1; //se habilitan las interrupciones de los perifericos
    INTCONbits.GIE  = 1; //se habilitan las interrupciones globales
    //PIE1bits.TMR2IE = 1; //se habilitan las interrupciones del tmr2
    ADCON0bits.GO = 1;  //se comienza la conversion adc
    while (1){}      
}