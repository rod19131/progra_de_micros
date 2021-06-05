/* * Archivo:     lab9.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Proyecto final
 * Hardware:    6 pots en puerto A y E y 2 servos en CCP1, CCP2, D0, D1, D2 y D3
 * Creado:      25 de abril de 2021, 10:25 AM
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
unsigned char potbang0, potbang1, potbang2, potbang3; //mapeo pots
unsigned char contpot0, contpot1, contpot2, contpot3 = 0; //iteraciones tmr0
unsigned char habcont0, habcont1, habcont2, habcont3 = 0;
//funciones
//mapeo del valor del pot a reseteos del tmr0 para generar el pulso deseado
unsigned char numresets(unsigned char potbang){
    unsigned char tmr0resets; //reseteos del tmr0
    if (potbang <= 20)
    {
        tmr0resets = 2;
    }
    else if (potbang > 20 && potbang <= 40)
    {
        tmr0resets =  3;
    }
    else if (potbang > 40 && potbang <= 60 )
    {
        tmr0resets =  4;
    }
    else if (potbang > 60 && potbang <= 80)
    {
        tmr0resets =  5;
    }
    else if (potbang > 80 && potbang <= 100 )
    {
        tmr0resets =  6;
    }
    else if (potbang > 100 && potbang <= 120)
    {
        tmr0resets =  7;
    }
    else if (potbang > 120 && potbang <= 140)
    {
        tmr0resets =  8;
    }
    else if (potbang > 140 &&  potbang <= 160)
    {
        tmr0resets =  9;
    }
    else if (potbang > 160 && potbang <= 180)
    {
        tmr0resets =  10;
    }
    else if ( potbang > 180 && potbang <= 200)
    {
        tmr0resets =  11;
    }
    else if (potbang > 200 && potbang <= 220)
    {
        tmr0resets =  12;
    }
    else  if (potbang > 220)
    {
        tmr0resets =  13;
    }
    return tmr0resets;
}
//----------------------interrupciones------------------------------------------
void __interrupt() isr(void){    // only process timer-triggered interrupts
    //interrupcion del adc
    if (ADIF == 1) {
        //multiplexacion de canales para el adc
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
                potbang0 = numresets(ADRESH>>1);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 3;//se cambia a canal del primer pot
                PORTB = ADRESH;
                break;
                
            case 3:
                potbang1 = numresets(ADRESH>>1);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 4;//se cambia a canal del primer pot
                break;
            
            case 4:
                potbang2 = numresets(ADRESH>>1);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 5;//se cambia a canal del primer pot
                break;
                
            case 5:
                potbang3 = numresets(ADRESH>>1);//para que el servo0 pueda girar 180
                ADCON0bits.CHS = 0;//se cambia a canal del primer pot
                break;
        }
        __delay_us(50);   //delay de 50 us
        PIR1bits.ADIF = 0;//interrupcion de adc
        ADCON0bits.GO = 1;//inicio de la siguiente conversión
    }
    if (INTCONbits.T0IF == 1){
        TMR0 = 234; //para que el tmr0 se reinicie cada 22 us
        //cuando el contador de iteraciones del tmr0 es igual al valor mapeado
        //se apaga el pin y se pone en 0 el contador para cada pot
        if (contpot0 == potbang0){
            PORTDbits.RD0 = 0;
            habcont0 = 0;
            contpot0 = 0;}
        if (contpot1 == potbang1){
            PORTDbits.RD1 = 0;
            habcont1 = 0;
            contpot1 = 0;}
        if (contpot2 == potbang2){
            PORTDbits.RD2 = 0;
            habcont2 = 0;
            contpot2 = 0;}
        if (contpot3 == potbang3){
            PORTDbits.RD3 = 0;
            habcont3 = 0;
            contpot3 = 0;}
        if (habcont0 == 1){
            contpot0++;}
        //se comienza a contar cuando el tmr1 se reinicia        
        if (habcont1 == 1){
            contpot1++;}
      
        if (habcont2 == 1){
            contpot2++;}
        
        if (habcont3 == 1){
            contpot3++;}
        INTCONbits.T0IF = 0;
    }
    if (PIR1bits.TMR1IF == 1){
        TMR1L = 192; //reinicio cada 20 ms
        TMR1H = 99;
        habcont0 = 1; // se encienden todos los pines de los servos para comenzar
        habcont1 = 1; // el pulso y se setean las variables para avisar en la 
        habcont2 = 1; // interrupcion del tmr0
        habcont3 = 1;
        PORTDbits.RD0 = 1; 
        PORTDbits.RD1 = 1;
        PORTDbits.RD2 = 1;
        PORTDbits.RD3 = 1;
        PIR1bits.TMR1IF = 0;}}

void main(void) {
    //configuraciones
    //configuracion reloj
    OSCCONbits.IRCF = 0b0111;//0111, Frecuencia de reloj 8 MHz
    OSCCONbits.SCS   = 1;//reloj interno
    //configuracion in out
    ANSELH = 0; //Pines digitales
    ANSELbits.ANS0  = 1;//RA0 y RA1 como pines analogicos
    ANSELbits.ANS1  = 1;
    ANSELbits.ANS2  = 1;
    ANSELbits.ANS3  = 1;
    ANSELbits.ANS4  = 1;
    ANSELbits.ANS5  = 1;
    TRISA  = 0b1111111; //PORT como inputs y los demas como outputs
    TRISB  = 0;
    TRISC  = 0;
    TRISD  = 0;
    TRISE  = 1;
    PORTA  = 0;//se limpian los puertos
    PORTB  = 0;
    PORTC  = 0;
    PORTD  = 0;
    PORTE  = 0;
    contpot0 = 0; //inicializacion
    contpot1 = 0;
    contpot2 = 0;
    contpot3 = 0;
    potbang0 = 0;
    potbang1 = 0;
    potbang2 = 0;
    potbang3 = 0;
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
    //configuracion tmr0
    OPTION_REGbits.T0CS = 0; //reloj interno (low to high)
    OPTION_REGbits.PSA  = 0; //prescaler 
    OPTION_REGbits.PS   = 0; //2
    //reset tmr0
    TMR0 = 234; //para que el tmr0 se reinicie cada 22 us
    INTCONbits.T0IF = 0; //baja la bandera de interrupcion del tmr0
    //configuracion tmr1
    TMR1L = 192; //reinicio cada 20 ms
    TMR1H = 99;
    T1CONbits.T1CKPS = 3; //prescale 8
    T1CONbits.TMR1CS = 0;
    T1CONbits.TMR1ON = 1;
    PIR1bits.TMR1IF = 0;
    //configuracion tmr2
    PIR1bits.TMR2IF = 0; //se apaga la bandera de interrupcion del tmr2
    T2CONbits.T2CKPS = 0b11;//prescaler 1:16
    T2CONbits.TMR2ON = 1;//se enciende el tmr2
    while(PIR1bits.TMR2IF == 0);//esperar un ciclo de tmr2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;//out pwm2
    TRISCbits.TRISC1 = 0;//out pwm1
    //configuracion interrupciones
    INTCONbits.T0IE = 1;
    PIE1bits.TMR1IE = 1;
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;   //se habilitan las interrupciones por adc
    INTCONbits.PEIE = 1; //se habilitan las interrupciones de los perifericos
    INTCONbits.GIE  = 1; //se habilitan las interrupciones globales
    ADCON0bits.GO = 1;  //se comienza la conversion adc
    while (1){}      
}