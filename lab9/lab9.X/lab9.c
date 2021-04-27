/*
 * Archivo:     lab9.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Laboratorio9: Servos con pots (modulo PWM1 y 2)
 * Hardware:    2 pots y 2 servos en el puertoA
 * Creado:      25 de abril de 2021, 10:25 AM
 * Ultima modificacion: 19 de abril de 2021
 */
#define _XTAL_FREQ 8000000
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

//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion del adc
    if (ADIF == 1) {
        //multiplexacion de canales para el adc
        //canal LEDs
        if(ADCON0bits.CHS == 0){
            CCPR1L = (ADRESH>>1)+128;//se actualizan los LEDs con valor de pot0
            CCP1CONbits.DC1B1 = ADRESH & 0b01;
            CCP1CONbits.DC1B0 = (ADRESL>>7);
            ADCON0bits.CHS = 1; //se cambia a canal de displays
        }
        //canal displays
        else{
            PORTD = ADRESH;        //se actualizan los displays con valor de pot1
            ADCON0bits.CHS = 0;//se cambia a canal de LEDs
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
    ADCON1bits.ADFM = 0; //se justifica a la izquierda, vals más significativos
    ADCON1bits.VCFG0 = 0;//0V a 5V
    ADCON1bits.VCFG1 = 0;//se ponen los voltajes de referencia internos del PIC
    ADCON0bits.ADCS = 2;//10 se selecciona Fosc/32 para conversion 4us full TAD
    ADCON0bits.CHS0 = 0;//se selecciona el canal AN0
    ADCON0bits.ADON = 1;//se enciende el adc
    __delay_us(50);   //delay de 50 us
    //configuracion pwm
    TRISCbits.TRISC2 = 1;      //CCP1 como entrada;
    PR2 = 249;                 //valor para que el periodo pwm sea 2 ms 124
    CCP1CONbits.P1M = 0;       //config pwm
    CCP1CONbits.CCP1M = 0b1100;
    CCPR1L = 0x0f;             //ciclo de trabajo inicial
    CCP1CONbits.DC1B = 0;
    //configuracion tmr2
    PIR1bits.TMR2IF = 0; //se apaga la bandera de interrupcion del tmr2
    T2CONbits.T2CKPS = 0b11;//prescaler 1:16
    T2CONbits.TMR2ON = 1;//se enciende el tmr2
    while(PIR1bits.TMR2IF == 0);//esperar un ciclo de tmr2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;//out pwm
    //configuracion interrupciones
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;   //se habilitan las interrupciones por adc
    INTCONbits.PEIE = 1; //se habilitan las interrupciones de los perifericos
    INTCONbits.GIE  = 1; //se habilitan las interrupciones globales
    //PIE1bits.TMR2IE = 1; //se habilitan las interrupciones del tmr2
    ADCON0bits.GO = 1;  //se comienza la conversion adc
    while (1)
    {if (ADCON0bits.GO == 0){
        ADCON0bits.GO = 1;
    } 
    }      
}