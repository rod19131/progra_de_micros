/*
 * Archivo:     proyectovacas.c
 * Dispositivo: PIC16F887
 * Autor:       Jose Alejandro Rodriguez Porras
 * Compilador:  XC8 MPLABX V5.40
 * Programa:    Proyecto vacaciones
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
unsigned char addpotccp1 = 0x04;
unsigned char addpotccp2 = 0x05;
unsigned char addpot0 = 0x06;
unsigned char addpot1 = 0x07;
unsigned char addpot2 = 0x08;
unsigned char addpot3 = 0x09;
unsigned char savedpos = 0;
unsigned char writepos = 0;

//unsigned char addpot0[] = {0x04,0x05,0x06,0x07,0x08};
//unsigned char addpot1[] = {0x09,0x0A,0x0B,0x0C,0x0D};
//unsigned char addpot2[] = {0x0E,0x0F,0x10,0x11,0x12};
//unsigned char addpot3[] = {0x13,0x14,0x15,0x16,0x17};
//unsigned char addpot4[] = {0x18,0x19,0x1A,0x1B,0x1C};
//unsigned char addpot5[] = {0x1D,0x1E,0x1F,0x20,0x21};
//------------------------------------------------------------------------------
//***************************** Funciones  *************************************
unsigned char mapear(unsigned char adresval){
    return (adresval-0)*(254-80)/(255-0)+80;}

void write(unsigned char data, unsigned char address){
    EEADR = address;
    EEDAT = data;
    
    EECON1bits.EEPGD = 0;   // Escribir a memoria de datos
    EECON1bits.WREN = 1;    // Habilitar escritura a EEPROM (datos)
    
    INTCONbits.GIE = 0;     // Deshabilitar interrupciones
    
    EECON2 = 0x55;          // Secuencia obligatoria
    EECON2 = 0xAA;
    EECON1bits.WR = 1;      // Escribir
    
    while(PIR2bits.EEIF==0);
    PIR2bits.EEIF = 0;
    
    INTCONbits.GIE = 1;     // Habilitar interrupciones
    EECON1bits.WREN = 0;    // Deshabilitar escritura de EEPROM

}

unsigned char   read(unsigned char   address){
    EEADR = address;        // direccion a leer
    EECON1bits.EEPGD = 0;   // memoria de datos
    EECON1bits.RD = 1;      // hace una lectura
    unsigned char  data = EEDAT;   // guardar el dato leído de EEPROM
    //__delay_ms(20);
    return data;
}

void Envio_caracter (char a){
    while (TXSTAbits.TRMT == 0){
       
    }
    if (PIR1bits.TXIF){
            TXREG = a;
        }  
}

void Envio_Cadena (char* cadena){
    while (*cadena != 0){
      Envio_caracter(*cadena);
      cadena++;
    }
    if (PIR1bits.TXIF){
            TXREG = 13;
        } 
}
//------------------------------------------------------------------------------
//*************************** Interrupciones ***********************************
void __interrupt() isr (void){
    // Interrupcion del ADC module
    if (RBIF == 1) {
        if (PORTBbits.RB0 == 0){
            writepos = 1;
        }
        else if (PORTBbits.RB1 == 0){
            switch (savedpos){
                case 1:
                    savedpos = 0;
                    break;
                case 0:
                    savedpos = 1;
                    CCPR1L = read(addpotccp1);
                    CCPR2L = read(addpotccp2);
                    valservo0 = read(addpot0);
                    valservo1 = read(addpot1);
                    valservo2 = read(addpot2);
                    valservo3 = read(addpot3);
                    break;
            }
            }
        else if (PORTBbits.RB2 == 0){
            
        }
        INTCONbits.RBIF = 0;
    }
    if (ADIF == 1) {
        //multiplexacion de canales para el adc
        //canal pwm1
        if (savedpos == 0){
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
    //configuraciones
    //configuracion reloj
    OSCCONbits.IRCF = 0b111;//111, Frecuencia de reloj 8 MHz
    OSCCONbits.SCS   = 1;//reloj interno
     //configuracion in out
    ANSELH = 0; //Pines digitales
    ANSELbits.ANS0 = 1;//RA0 y RA1 como pines analogicos
    ANSELbits.ANS1 = 1;
    ANSELbits.ANS2 = 1;
    ANSELbits.ANS3 = 1;
    ANSELbits.ANS4 = 1;
    ANSELbits.ANS5 = 1;
    TRISA = 0b11111111; //RA0 y RA1 como inputs y los demas como outputs
    TRISB = 7;
    TRISC = 0;
    TRISD = 0;
    TRISE = 1;
    PORTA = 0;//se limpian los puertos
    PORTC = 0;
    PORTB = 0;
    PORTD = 0;
    PORTE = 0;
    
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB = 7;//habilitar pull-ups
    
    //configuracion interrupt on change b
    IOCBbits.IOCB0 = 1; //Se habilita la interrupcion por cambio en RB0 y RB1
    IOCBbits.IOCB1 = 1;
    IOCBbits.IOCB2 = 1;
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
    OPTION_REGbits.PS = 7;
    TMR0 = 100;
    //configuracion tmr2
    PIR1bits.TMR2IF = 0; //se apaga la bandera de interrupcion del tmr2
    T2CONbits.T2CKPS = 0b11;//prescaler 1:16
    T2CONbits.TMR2ON = 1;//se enciende el tmr2
    while(PIR1bits.TMR2IF == 0);//esperar un ciclo de tmr2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;//out pwm2
    TRISCbits.TRISC1 = 0;//out pwm1
    //TX y RX
    TXSTAbits.SYNC = 0;
    TXSTAbits.BRGH = 1;
    
    BAUDCTLbits.BRG16 = 1;
    
    SPBRG = 207;
    SPBRGH = 0;
    
    RCSTAbits.SPEN = 1;
    RCSTAbits.RX9 = 0;
    RCSTAbits.CREN = 1;
    
    TXSTAbits.TXEN = 1;
    //configuracion interrupciones
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;   //se habilitan las interrupciones por adc
    INTCONbits.PEIE = 1; //se habilitan las interrupciones de los perifericos
    INTCONbits.GIE  = 1; //se habilitan las interrupciones globales
    INTCONbits.T0IE = 1;
    INTCONbits.T0IF = 0;
    INTCONbits.RBIE = 1; //interrupcion on change habilitada
    ADCON0bits.GO = 1;  //se comienza la conversion adc

    while(1){if (writepos == 1){
                write(CCPR1L, addpotccp1);
                write(CCPR2L, addpotccp2);
                write(valservo0, addpot0);
                write(valservo1, addpot1);
                write(valservo2, addpot2);
                write(valservo3, addpot3);
                writepos = 0;}} 
}
