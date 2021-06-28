/*
 * Archivo:     proyectovacas.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Laboratorio9: Servos con pots (modulo PWM1 y 2)
 * Hardware:    2 pots en puerto A y 2 servos en CCP1 y CCP2
 * Creado:      14 de junio de 2021, 05:09 PM
 * Ultima modificacion: 26 de abril de 2021
 */
//CONFIGURATION WORD 1
#include <xc.h>
#pragma config FOSC=INTRC_NOCLKOUT //Oscilador interno sin salida
#pragma config WDTE=OFF           //Reinicio repetitivo del pic
#pragma config PWRTE=OFF           //no espera de 72 ms al iniciar el pic
#pragma config MCLRE=OFF          //El pin MCLR se utiliza como entrada/salida
#pragma config CP=OFF             //Sin protección de código
#pragma config CPD=OFF            //Sin protección de datos
    
#pragma config BOREN=OFF //Sin reinicio cuando el input voltage es inferior a 4V
#pragma config IESO=OFF  //Reinicio sin cambio de reloj de interno a externo
#pragma config FCMEN=OFF //Cambio de reloj externo a interno en caso de fallas
#pragma config LVP=OFF    //Programación en low voltage apagada
    
//CONFIGURATION WORD 2
#pragma config WRT=OFF //Proteccion de autoescritura por el programa desactivada
#pragma config BOR4V=BOR40V //Reinicio abajo de 4V 
#define _XTAL_FREQ 8000000 //frecuencia de 8 MHz

//------------------------------------------------------------------------------
//********************* Declaraciones de variables *****************************

unsigned char contservo0;
unsigned char contservo1;
unsigned char contservo2;
unsigned char contservo3;
unsigned char valservo0;
unsigned char valservo1;
unsigned char valservo2;
unsigned char valservo3;
//------------------------------------------------------------------------------
//***************************** Funciones  *************************************
unsigned char mapear(unsigned char adresval){
    return (adresval-0)*(254-80)/(255-0)+80;}
//------------------------------------------------------------------------------
//*************************** Interrupciones ***********************************
void __interrupt() isr (void){
    // Interrupcion del ADC module
    if (ADIF == 1) {
        //multiplexacion de canales para el adc
        //canal pwm1
        switch (ADCON0bits.CHS){
            case 0:
                CCPR1L = (ADRESH>>1)+124;//para que el servo1 pueda girar 180 g
                ADCON0bits.CHS = 1; //se cambia al canal del segundo pot
                break;
                
            case 1:
                CCPR2L = (ADRESH>>1)+124;//para que el servo0 pueda girar 180 g
                ADCON0bits.CHS = 2;//se cambia a canal del primer pot
                break;
            
            case 2:
                valservo0 = mapear(ADRESH);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 3;//se cambia a canal del primer pot
                break;
            
            case 3:
                valservo1 = mapear(ADRESH);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 4;//se cambia a canal del primer pot
                break;
            
            case 4:
                valservo2 = mapear(ADRESH);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 5;//se cambia a canal del primer pot
                break;
                
            case 5:
                valservo3 = mapear(ADRESH);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 0;//se cambia a canal del primer pot
                break;    
        }
        __delay_us(20);   //delay de 20 us
        PIR1bits.ADIF = 0;//interrupcion de adc
        ADCON0bits.GO = 1;//inicio de la siguiente conversión
    
    }
    
    // Interrupcion del timer0
    if (T0IF == 1){
        // Interrupcion cada 20ms: tmr0 100, prescaler 256, 8MHz de oscilador
        T0IF = 0;
        TMR0 = 100;
        // PWM
        contservo0 = 0;
        contservo1 = 0;
        contservo2 = 0;
        contservo3 = 0;
        // SERVO 1
        RD0 = 1;
        __delay_us(465);   //delay de 20 us
        while (contservo0 <= valservo0){ // max 199, min 98 
            contservo0++;
        }
        RD0=0;
        // SERVO 2
        RD1 = 1;
        __delay_us(465);   //delay de 20 us
        while (contservo1 <= valservo1){ // max 199, min 98 
            contservo1++;
        }
        RD1=0;
        // SERVO 3
        RD2 = 1;
        __delay_us(465);   //delay de 20 us
        while (contservo2 <= valservo2){ // max 199, min 98 
            contservo2++;
        }
        RD2=0;
        RD3 = 1;
        __delay_us(465);   //delay de 20 us
        while (contservo3 <= valservo3){ // max 199, min 98 
            contservo3++;
        }
        RD3=0;
    } // Fin de interrupci贸n timer0
}    

void main(void) {
    // Oscilador
    IRCF0 = 1;       // Configuraci贸n del reloj interno 
    IRCF1 = 1;
    IRCF2 = 1;       // 8 Mhz   
    
    // Configurar Timer0
    PS0 = 1;
    PS1 = 1;
    PS2 = 1;         //Prescaler de 256
    T0CS = 0;
    PSA = 0;
    INTCON = 0b10101000;
    TMR0 = 100;
    
    // Configuraci贸n del modulo ADC
    PIE1bits.ADIE = 1;
    ADIF = 0; // Bandera de interrupci贸n
    ADCON1bits.ADFM = 0; // Justificado a la izquierda    
    ADCON1bits.VCFG0 = 0;
    ADCON1bits.VCFG0 = 0; // Voltajes de referencia en VSS y VDD
    ADCON0bits.ADCS0 = 0;
    ADCON0bits.ADCS1 = 1; // FOSC/8
    ADCON0bits.ADON = 1;
    __delay_us(50);
    ADCON0bits.GO = 1;
    
    // Configurar puertos
    ANSEL  = 0b00111111;
    ANSELH = 0;
    TRISA  = 0xff;  // Definir el puerto A como entradas
    TRISC  = 0;     // Definir el puerto C como salida
    TRISD  = 0;     // Definir el puerto D como salida
    TRISE  = 1;     // Definir el puerto E como salida
    
    //Limpieza de puertos
    PORTA = 0;
    PORTB = 0;
    PORTC = 0;
    PORTD = 0;
    PORTE = 0;
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
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    PIE1bits.TMR1IE = 1;
    PIR1bits.TMR1IF = 0;
    ADCON0bits.GO = 1;  //se comienza la conversion adc
    
    //loop principal
    while(1){
    } // fin loop principal while 
} // fin main
