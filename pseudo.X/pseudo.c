/*
 * File:   Servos.c
 * Author: Fredy 
 *
 */


#include <xc.h>
#define _XTAL_FREQ 8000000
// PIC16F887 Configuration Bit Settings

// 'C' source line config statements

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
char Valor_TMR0 = 100;
int Contador_Servo_1;
int Contador_Servo_2;
int Contador_Servo_3;
char Valor_Servo_1;
char Valor_Servo_2;
char Valor_Servo_3;
char ADRESH_Servo_1;
char ADRESH_Servo_2;
char ADRESH_Servo_3;
//------------------------------------------------------------------------------
//***************************** Prototipos *************************************

//------------------------------------------------------------------------------
//*************************** Interrupciones ***********************************
void __interrupt() isr (void){
    // Interrupcion del ADC module
    if (ADIF == 1){
        ADIF = 0;
        if (ADCON0bits.CHS == 0){
            ADRESH_Servo_1 = ADRESH;
            ADCON0bits.CHS = 1;
        } else if(ADCON0bits.CHS == 1){
            ADRESH_Servo_2 = ADRESH;
            ADCON0bits.CHS = 2;
        } else if(ADCON0bits.CHS == 2){
            ADRESH_Servo_3 = ADRESH;
            ADCON0bits.CHS = 0;
        }   
        __delay_us(50);
        ADCON0bits.GO = 1; 
    }
    
    // Interrupcion del timer0
    if (T0IF == 1){
        // Interrupcion cada 20ms: tmr0 100, prescaler 256, 8MHz de oscilador
        PIE1bits.ADIE = 0;
        T0IF = 0;
        TMR0 = Valor_TMR0;
        // PWM
        Contador_Servo_1 = 0;
        Contador_Servo_2 = 0;
        Contador_Servo_3 = 0;
        // SERVO 1
        RD0 = 1;
        while (Contador_Servo_1 <= Valor_Servo_1){ // max 199, min 98 
            Contador_Servo_1++;
        }
        RD0=0;
        // SERVO 2
        RD1 = 1;
        while (Contador_Servo_2 <= Valor_Servo_2){ // max 199, min 98 
            Contador_Servo_2++;
        }
        RD1=0;
        // SERVO 3
        RD2 = 1;
        while (Contador_Servo_3 <= Valor_Servo_3){ // max 199, min 98 
            Contador_Servo_3++;
        }
        RD2=0;
        PIE1bits.ADIE = 1;
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
    TMR0 = Valor_TMR0;
    
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
    ANSEL  = 0b00000111;
    ANSELH = 0;
    TRISA  = 0xff;  // Definir el puerto A como entradas
    TRISC  = 0;     // Definir el puerto C como salida
    TRISD  = 0;     // Definir el puerto D como salida
    TRISE  = 0;     // Definir el puerto E como salida
    
    //Limpieza de puertos
    PORTA = 0;
    PORTB = 0;
    PORTC = 0;
    PORTD = 0;
    PORTE = 0;
    
    //loop principal
    while(1){  
        Valor_Servo_1 = (ADRESH_Servo_1-0)*(199-98)/(255-0)+98;
        Valor_Servo_2 = (ADRESH_Servo_2-0)*(199-98)/(255-0)+98;
        Valor_Servo_3 = (ADRESH_Servo_3-0)*(199-98)/(255-0)+98;
    } // fin loop principal while 
} // fin main