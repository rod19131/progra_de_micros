/*
 * File:   pseudopro2.c
 * Author: Alejandro Rodríguez
 *
 * Created on 2 de junio de 2021, 06:31 PM
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
//**************************
//                              VARIABLES
//**************************

unsigned char   POT0;
unsigned char   POT1;
unsigned char   POT2;
unsigned char   ItPOT0;
unsigned char   ItPOT1;
unsigned char   ItPOT2;
unsigned char   ENTM0Pot0;
unsigned char   ENTM0Pot1;
unsigned char   ENTM0Pot2;
unsigned char   ConTMR1;
unsigned char   ConTEEPROM = 0;
unsigned char   ADD_POT0[5] = {0x04,0x05,0x06,0x07,0x08};
unsigned char   ADD_POT1[5] = {0x09,0x0A,0x0B,0x0C,0x0D};
unsigned char   ADD_POT2[5] = {0x0E,0x0F,0x10,0x11,0x12};
unsigned char   ADD_POT3[5] = {0x13,0x14,0x15,0x16,0x17};
unsigned char   DC1B1POT3[5] = {0x18,0x19,0x1A,0x1B,0x1C};
unsigned char   RB0_old = 0;
unsigned char   RB1_old = 0;
unsigned char   Reading = 0;
unsigned char   PC_MN = 0;


//**************************
//                              FUNCIONES
//**************************
unsigned char NumIteraciones (unsigned char ValorPot)
{
    if (ValorPot <19)
    {
        return 2;
    }
    else if (ValorPot < 40 && ValorPot > 18)
    {
        return 3;
    }
    else if (ValorPot < 61 && ValorPot > 39)
    {
        return 5;
    }
    else if (ValorPot < 82 && ValorPot > 60)
    {
        return 6;
    }
    else if (ValorPot < 103 && ValorPot > 81)
    {
        return 7;
    }
    else if (ValorPot < 131 && ValorPot > 102)
    {
        return 8;
    }
    else if (ValorPot < 152 && ValorPot > 130)
    {
        return 9;
    }
    else if (ValorPot < 173 && ValorPot > 151)
    {
        return 10;
    }
    else if (ValorPot < 194 && ValorPot > 172)
    {
        return 11;
    }
    else if (ValorPot < 215 && ValorPot > 193)
    {
        return 12;
    }
    else if (ValorPot < 236 && ValorPot > 214)
    {
        return 14;
    }
    else
    {
        return 15;
    }
}

void writeToEEPROM(unsigned char data, unsigned char address){
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
    
    return;
}
unsigned char   readFromEEPROM(unsigned char   address){
    EEADR = address;        // direccion a leer
    EECON1bits.EEPGD = 0;   // memoria de datos
    EECON1bits.RD = 1;      // hace una lectura
    unsigned char  data = EEDAT;   // guardar el dato leído de EEPROM
    return data;
}

void readFromEEPROMPOTS(void){
    ConTEEPROM = 0;
    Reading = 1;
    while (ConTEEPROM < 5){
        switch(ConTEEPROM){
            case 0:
                CCPR1L = readFromEEPROM(ADD_POT3[0]);
                CCP1CONbits.DC1B1 = readFromEEPROM(DC1B1POT3[0]) & 0b00100000;
                CCP1CONbits.DC1B0 = readFromEEPROM(DC1B1POT3[0]) & 0b00010000;
                POT0 = readFromEEPROM(ADD_POT0[0]);
                POT1 = readFromEEPROM(ADD_POT1[0]);
                POT2 = readFromEEPROM(ADD_POT2[0]);
                PORTDbits.RD3 = 1;
                PORTDbits.RD4 = 0;
                PORTDbits.RD5 = 0;
                PORTDbits.RD6 = 0;
                PORTDbits.RD7 = 0;
                __delay_ms(100);
                ConTEEPROM = 1;
               break;

            case 1:
                CCPR1L = readFromEEPROM(ADD_POT3[1]);
                CCP1CONbits.DC1B1 = readFromEEPROM(DC1B1POT3[1]) & 0b00100000;
                CCP1CONbits.DC1B0 = readFromEEPROM(DC1B1POT3[1]) & 0b00010000;
                POT0 = readFromEEPROM(ADD_POT0[1]);
                POT1 = readFromEEPROM(ADD_POT1[1]);
                POT2 = readFromEEPROM(ADD_POT2[1]);
                PORTDbits.RD4 = 1;
                __delay_ms(100);
                ConTEEPROM = 2;
               break;

            case 2:
                CCPR1L = readFromEEPROM(ADD_POT3[2]);
                CCP1CONbits.DC1B1 = readFromEEPROM(DC1B1POT3[2]) & 0b00100000;
                CCP1CONbits.DC1B0 = readFromEEPROM(DC1B1POT3[2]) & 0b00010000;
                POT0 = readFromEEPROM(ADD_POT0[2]);
                POT1 = readFromEEPROM(ADD_POT1[2]);
                POT2 = readFromEEPROM(ADD_POT2[2]);
                PORTDbits.RD5 = 1;
                __delay_ms(100);
                ConTEEPROM = 3;
               break;
            case 3:
                CCPR1L = readFromEEPROM(ADD_POT3[3]);
                CCP1CONbits.DC1B1 = readFromEEPROM(DC1B1POT3[3]) & 0b00100000;
                CCP1CONbits.DC1B0 = readFromEEPROM(DC1B1POT3[3]) & 0b00010000;
                POT0 = readFromEEPROM(ADD_POT0[3]);
                POT1 = readFromEEPROM(ADD_POT1[3]);
                POT2 = readFromEEPROM(ADD_POT2[3]);
                PORTDbits.RD6 = 1;
                __delay_ms(100);
                ConTEEPROM = 4;
               break;

            case 4:
                CCPR1L = readFromEEPROM(ADD_POT3[4]);
                CCP1CONbits.DC1B1 = readFromEEPROM(DC1B1POT3[4]) & 0b00100000;
                CCP1CONbits.DC1B0 = readFromEEPROM(DC1B1POT3[4]) & 0b00010000;
                POT0 = readFromEEPROM(ADD_POT0[4]);
                POT1 = readFromEEPROM(ADD_POT1[4]);
                POT2 = readFromEEPROM(ADD_POT2[4]);
                PORTDbits.RD7 = 1;
                __delay_ms(100);
                ConTEEPROM = 5;
               break;
        }
    }
    Reading = 0;
    ConTEEPROM = 0;
    return;
}

//**************************
//                              INTERRUPCIÓN
//**************************
void __interrupt() isr(void){    
    
    //Interrupción ADC
    if (ADIF == 1) {
        if (Reading == 0 && PC_MN == 0){
        switch (ADCON0bits.CHS){
            case 0:
                POT0 = NumIteraciones(ADRESH);          //Se guarda el valor del POT1
                ADCON0bits.CHS = 1;     //cambio para el multiplexeo
                break;
        
            case 1:
                POT1 = NumIteraciones(ADRESH);         //Se guarda el valor del POT1
                ADCON0bits.CHS = 2;     //cambio para el multiplexeo
                break;
        
            case 2:
                POT2 = NumIteraciones(ADRESH);          //Se guarda el valor del POT1
                ADCON0bits.CHS = 3;     //cambio para el multiplexeo
                break;
            
           case 3:
                CCPR1L = (ADRESH>>1)+124;//habilita 180°
                CCP1CONbits.DC1B1 = ADRESH & 0b01; //añadir precision/resolucion
                CCP1CONbits.DC1B0 = (ADRESL>>7);
                ADCON0bits.CHS = 0;
                break;
        }
      }
        __delay_us(20);             //delay de 20 us
        PIR1bits.ADIF = 0;          //limpieza de bandera
        ADCON0bits.GO = 1;          //inicio de conversión
    }
    
   if (T0IF == 1) {                
        TMR0 = 228;                 //reseteo de timer0
        if (ItPOT0 == POT0){
            PORTDbits.RD0 = 0;
            ItPOT0 = 0;
            ENTM0Pot0 = 0;
        }
        if (ItPOT1 == POT1){
            PORTDbits.RD1 = 0;
            ItPOT1 = 0;
            ENTM0Pot1 = 0;
        }
        if (ItPOT2 == POT2){
            PORTDbits.RD2 = 0;
            ItPOT2 = 0;
            ENTM0Pot2 = 0;
        }
        if (ENTM0Pot0 == 1){
            ItPOT0++;
        }
        if (ENTM0Pot1 == 1){
            ItPOT1++;
        }
        if (ENTM0Pot2 == 1){
            ItPOT2++;
        }
        INTCONbits.T0IF = 0;        //limpieza de bandera
    }
    
    if (TMR1IF == 1){
        TMR1H = 255;
        TMR1L = 6;
        if (ConTMR1 == 1){
           ENTM0Pot0 = 1; 
           ENTM0Pot1 = 1; 
           ENTM0Pot2 = 1; 
        }   
        
        if (ConTMR1 == 20){
            ConTMR1 = 0;
            PORTDbits.RD0 = 1;
            PORTDbits.RD1 = 1;
            PORTDbits.RD2 = 1;
        }
        ConTMR1++;
        PIR1bits.TMR1IF = 0;       //limpieza de TMR1 
    }
}
        


void main(void) {
//**************************
//                              CONFIGURACIONES
//**************************
    
    //RELOJ
    OSCCONbits.IRCF = 0b0111;       //Reloj a 8 MHz
    OSCCONbits.SCS   = 1;
    
    
    //INPUTS/OUTPUTS
    ANSELH = 0;                     
    ANSELbits.ANS0  = 1;            //RA: 0,1,2,3 entradas analogas
    ANSELbits.ANS1  = 1;
    ANSELbits.ANS2  = 1;
    ANSELbits.ANS3  = 1;
    TRISA  = 0b11111111;            //PORTA inputs
    TRISD  = 0;                     //PORTD salidas
    TRISE  = 0;                     //PORTD salidas
    TRISB  = 0b00000011;                     //PORTD salidas
    OPTION_REGbits.nRBPU = 0;
    WPUBbits.WPUB0 = 1;             //habilitar pull-ups
    WPUBbits.WPUB1 = 1;
    TRISC  = 0;
    PORTA  = 0;                     //limpieza de puertos
    PORTD  = 0;
    PORTB  = 0b00000011;
    PORTC  = 0;
    PORTE  = 0;
    ItPOT0 = 0;
    ItPOT1 = 0;
    ItPOT2 = 0;
    POT0 = 0;
    POT1 = 0;
    POT2 = 0;
    ConTMR1 = 0;
    
    
    //ADC
    ADCON0bits.ADCS = 2;            //Fosc/32 
    ADCON0bits.CHS0 = 0;            //se selecciona el canal AN0
    ADCON1bits.VCFG1 = 0;           //voltajes referencia default
    ADCON1bits.VCFG0 = 0;           
    ADCON1bits.ADFM = 0;            //justificación izquierda
    ADCON0bits.ADON = 1;            
    __delay_us(20);                 //delay de 20 us
    
    
    //PWM
    TRISCbits.TRISC2 = 1;           //CCP1 como entrada;
    PR2 = 250;                      //valor para que el periodo pwm sea 2 ms 
    CCP1CONbits.P1M = 0;       
    CCP1CONbits.CCP1M = 0b1100;
    CCPR1L = 0x0f;                  //ciclo de trabajo inicial
    CCP1CONbits.DC1B = 0;
    
    //TMR2
    PIR1bits.TMR2IF = 0;            //limpieza de bandera
    T2CONbits.T2CKPS = 0b11;        //prescaler 1:16
    T2CONbits.TMR2ON = 1;           
    while(PIR1bits.TMR2IF == 0);    //esperar un ciclo de tmr2
    PIR1bits.TMR2IF = 0;
    TRISCbits.TRISC2 = 0;           
    TRISCbits.TRISC1 = 0;   
    
    //TMR0
    OPTION_REGbits.T0CS = 0;
    OPTION_REGbits.PSA  = 0;
    OPTION_REGbits.PS2  = 0;
    OPTION_REGbits.PS1  = 0;
    OPTION_REGbits.PS0  = 0;        //prescaler a 2
    TMR0 = 228;                      //reseteo TMR0
    INTCONbits.T0IF = 0;
    
    //TMR1
    T1CONbits.TMR1ON = 1;
    T1CONbits.TMR1CS = 0;
    T1CONbits.TMR1CS = 0;
    T1CONbits.T1CKPS1 = 1;
    T1CONbits.T1CKPS0 = 1;          //prescaler a 8
    TMR1H = 255;
    TMR1L = 6;
    PIR1bits.TMR1IF = 0;            //limpieza de la bandera
    
    /*
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
    */

    //INTERRUPCIONES
    PIR1bits.ADIF = 0;
    PIE1bits.ADIE = 1;              //interrupción ADC
    INTCONbits.PEIE = 1;            
    INTCONbits.GIE  = 1; 
    INTCONbits.T0IE  = 1;           //interrupción del TMR0
    PIE1bits.TMR1IE = 1;            //interrupcion del TMR1
    ADCON0bits.GO = 1;              
    while (1){
        if (RB0 == 0)
            RB0_old = 1;
        
        if (RB1 == 0)
            RB1_old = 1;
        
        if (RB0 == 1 && RB0_old == 1 && PC_MN == 0 ){
            switch(ConTEEPROM){
                case 0:
                   writeToEEPROM(CCPR1L,ADD_POT3[0]);
                   writeToEEPROM(CCP1CON,DC1B1POT3[0]);
                   writeToEEPROM(POT0,ADD_POT0[0]); 
                   writeToEEPROM(POT1,ADD_POT1[0]); 
                   writeToEEPROM(POT2,ADD_POT2[0]); 
                   ConTEEPROM = 1;
                   PORTDbits.RD3 = 1;
                   PORTDbits.RD4 = 0;
                   PORTDbits.RD5 = 0;
                   PORTDbits.RD6 = 0;
                   PORTDbits.RD7 = 0;
                   break;
                
                case 1:
                   writeToEEPROM(CCPR1L,ADD_POT3[1]);
                   writeToEEPROM(CCP1CON,DC1B1POT3[1]);
                   writeToEEPROM(POT0,ADD_POT0[1]); 
                   writeToEEPROM(POT1,ADD_POT1[1]); 
                   writeToEEPROM(POT2,ADD_POT2[1]); 
                   ConTEEPROM = 2;
                   PORTDbits.RD4 = 1;
                   break;
                
                case 2:
                   writeToEEPROM(CCPR1L,ADD_POT3[2]);
                   writeToEEPROM(CCP1CON,DC1B1POT3[2]);
                   writeToEEPROM(POT0,ADD_POT0[2]); 
                   writeToEEPROM(POT1,ADD_POT1[2]); 
                   writeToEEPROM(POT2,ADD_POT2[2]); 
                   ConTEEPROM = 3;
                   PORTDbits.RD5 = 1;
                   break;
                
                case 3:
                   writeToEEPROM(CCPR1L,ADD_POT3[3]);
                   writeToEEPROM(CCP1CON,DC1B1POT3[3]);
                   writeToEEPROM(POT0,ADD_POT0[3]); 
                   writeToEEPROM(POT1,ADD_POT1[3]); 
                   writeToEEPROM(POT2,ADD_POT2[3]); 
                   ConTEEPROM = 4;
                   PORTDbits.RD6 = 1;
                   break;
                
                case 4:
                   writeToEEPROM(CCPR1L,ADD_POT3[4]);
                   writeToEEPROM(CCP1CON,DC1B1POT3[4]);
                   writeToEEPROM(POT0,ADD_POT0[4]); 
                   writeToEEPROM(POT1,ADD_POT1[4]); 
                   writeToEEPROM(POT2,ADD_POT2[4]); 
                   ConTEEPROM = 0;
                   PORTDbits.RD7 = 1;
                   break;  
            }
            RB0_old = 0;
        }
        
        if (RB1 == 1 && RB1_old == 1 && PC_MN == 0){
            readFromEEPROMPOTS();
            RB1_old = 0;
        }
    }      
}