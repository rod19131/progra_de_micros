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
//variables
//124
unsigned char contpot1 = 0;
unsigned char numpot1 = 50;
unsigned char numresets(unsigned char potbang){
    unsigned char tmr0resets;
    if (potbang > 0 && potbang < 7){
        tmr0resets = 50;
    } 
    else if (potbang > 6 && potbang < 13){
        tmr0resets = 51;
    }
    else if (potbang > 12 && potbang < 19){
        tmr0resets = 52;
    } 
    else if (potbang > 18 && potbang < 25){
        tmr0resets = 53;
    } 
    else if (potbang > 24 && potbang < 31){
        tmr0resets = 54;
    } 
    else if (potbang > 30 && potbang < 37){
        tmr0resets = 55;
    } 
    else if (potbang > 36 && potbang < 43){
        tmr0resets = 56;
    } 
    else if (potbang > 42 && potbang < 49){
        tmr0resets = 57;
    } 
    else if (potbang > 48 && potbang < 55){
        tmr0resets = 58;
    } 
    else if (potbang > 54 && potbang < 61){
        tmr0resets = 59;
    } 
    else if (potbang > 60 && potbang < 67){
        tmr0resets = 60;
    } 
    else if (potbang > 66 && potbang < 73){
        tmr0resets = 61;
    } 
    else if (potbang > 72 && potbang < 79){
        tmr0resets = 62;
    } 
    else if (potbang > 78 && potbang < 85){
        tmr0resets = 63;
    } 
    else if (potbang > 84 && potbang < 91){
        tmr0resets = 64;
    } 
    else if (potbang > 90 && potbang < 97){
        tmr0resets = 65;
    } 
    else if (potbang > 96 && potbang < 103){
        tmr0resets = 66;
    } 
    else if (potbang > 102 && potbang < 109){
        tmr0resets = 67;
    } 
    else if (potbang > 108 && potbang < 115){
        tmr0resets = 68;
    } 
    else if (potbang > 114 && potbang < 121){
        tmr0resets = 69;
    } 
    else if (potbang > 120 && potbang < 127){
        tmr0resets = 70;
    } 
    else if (potbang > 126 && potbang < 133){
        tmr0resets = 71;
    } 
    else if (potbang > 132 && potbang < 139){
        tmr0resets = 72;
    } 
    else if (potbang > 138 && potbang < 145){
        tmr0resets = 73;
    } 
    else if (potbang > 144 && potbang < 151){
        tmr0resets = 74;
    } 
    else if (potbang > 150 && potbang < 157){
        tmr0resets = 75;
    } 
    else if (potbang > 156 && potbang < 163){
        tmr0resets = 76;
    } 
    else if (potbang > 162 && potbang < 169){
        tmr0resets = 77;
    } 
    else if (potbang > 168 && potbang < 175){
        tmr0resets = 78;
    } 
    else if (potbang > 174 && potbang < 181){
        tmr0resets = 79;
    } 
    else if (potbang > 180 && potbang < 187){
        tmr0resets = 80;
    } 
    else if (potbang > 186 && potbang < 193){
        tmr0resets = 81;
    } 
    else if (potbang > 192 && potbang < 199){
        tmr0resets = 82;
    } 
    else if (potbang > 198 && potbang < 205){
        tmr0resets = 83;
    } 
    else if (potbang > 204 && potbang < 211){
        tmr0resets = 84;
    } 
    else if (potbang > 210 && potbang < 217){
        tmr0resets = 85;
    } 
    else if (potbang > 216 && potbang < 223){
        tmr0resets = 86;
    } 
    else if (potbang > 222 && potbang < 229){
        tmr0resets = 87;
    } 
    else if (potbang > 228 && potbang < 235){
        tmr0resets = 88;
    } 
    else if (potbang > 234 && potbang < 241){
        tmr0resets = 89;
    } 
    else if (potbang > 240 && potbang < 247){
        tmr0resets = 90;
    } 
    else if (potbang > 246 && potbang < 253){
        tmr0resets = 91;
    } 
    else if (potbang > 252 && potbang < 255){
        tmr0resets = 92;
    }  
    return tmr0resets;}
//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion del adc
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
                numpot1 = numresets(ADRESH);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 0;//se cambia a canal del primer pot
                break;}
        __delay_us(20);   //delay de 50 us
        PIR1bits.ADIF = 0;//interrupcion de adc
        ADCON0bits.GO = 1;//inicio de la siguiente conversión
    
    }
    if (T0IF == 1) {
        contpot1++;
        TMR0 = 236;
        T0IF = 0;
        if (contpot1 == numpot1){
            contpot1 = 0;
            PORTDbits.RD0 = 0;
        }
    }
    if (TMR1IF == 1){
        TMR1L = 192;
        TMR1H = 99;
        TMR1IF = 0;
        PORTDbits.RD0 = 1;
    }
    }

void main(void) {
    //configuraciones
    //configuracion reloj
    OSCCONbits.IRCF = 0b111;//111, Frecuencia de reloj 8 MHz
    OSCCONbits.SCS   = 1;//reloj interno
    //configuracion in out
    ANSELH = 0; //Pines digitales
    ANSELbits.ANS0  = 1;//RA0 y RA1 como pines analogicos
    ANSELbits.ANS1  = 1;
    ANSELbits.ANS2 = 1;
    TRISA  = 7; //RA0 y RA1 como inputs y los demas como outputs
    TRISC  = 0;
    TRISD = 0;
    PORTA  = 0;//se limpian los puertos
    PORTC  = 0;
    PORTB  = 0;
    PORTD  = 0;
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
    //configuracion trm0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA = 0;
    OPTION_REGbits.PS = 0;
    TMR0 = 236;
    //configuracion tmr1
    T1CONbits.T1CKPS = 0;
    T1CONbits.TMR1CS = 0;
    T1CONbits.TMR1ON = 1;
    TMR1L = 192;
    TMR1H = 99;
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
    while (1){}      
}
