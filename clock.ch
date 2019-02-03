WARNING: never write anything to USB host - this way you may use non-patched 
cdc-acm driver (on raspberry pi openwrt)

@x
volatile int keydetect = 0;
ISR(INT1_vect)
{
  keydetect = 1;
}
@y
void LCD_Command( unsigned char cmnd )
{
        PORTF = cmnd & 0xF0; /* sending upper nibble */
        PORTB &= ~ (1<<PB4);             /* RS=0, command reg. */
        PORTB |= (1<<PB5);               /* Enable pulse */
        _delay_us(1);
        PORTB &= ~ (1<<PB5);

        _delay_us(200);

        PORTF = cmnd << 4;  /* sending lower nibble */
        PORTB |= (1<<PB5);
        _delay_us(1);
        PORTB &= ~ (1<<PB5);
        _delay_ms(2);
}

void LCD_Char( unsigned char data )
{
        PORTF = data & 0xF0; /* sending upper nibble */
        PORTB |= (1<<PB4);               /* RS=1, data reg. */
        PORTB |= (1<<PB5);
        _delay_us(1);
        PORTB &= ~ (1<<PB5);
        _delay_us(200);

        PORTF = data << 4; /* sending lower nibble */
        PORTB |= (1<<PB5);
        _delay_us(1);
        PORTB &= ~ (1<<PB5);
        _delay_ms(2);
}

void LCD_Init (void)                    /* LCD Initialize function */
{
        DDRF |= 0xF0;                   /* Make LCD port direction as o/p */
        DDRB |= (1 << PB4) | (1 << PB5);
        _delay_ms(20);                  /* LCD Power ON delay always >15ms */

        LCD_Command(0x02);              /* send for 4 bit initialization of LCD  */
        LCD_Command(0x28);              /* 2 line, 5*7 matrix in 4-bit mode */
        LCD_Command(0x0c);              /* Display on cursor off*/
        LCD_Command(0x06);              /* Increment cursor (shift cursor to right)*/
        LCD_Command(0x01);              /* Clear display screen*/
        _delay_ms(2);
}
@z

@x
  UENUM = EP1;
@y
  UENUM = EP2;
@z

@x
  EICRA |= 1 << ISC11 | 1 << ISC10; /* set INT1 to trigger on rising edge */
  EIMSK |= 1 << INT1; /* turn on INT1; it happens
    only when the device is operational - we do not remove USB RESET interrupt, which
    happens only when device is rebooted - it can't happen that a
    to-be-processed-via-interrupt event occurs while an interrupt is being processed */
@y
@z

@x
  DDRE |= 1 << PE6;
@y
@z

@x
  char digit;
@y
  PORTE |= 1 << PE6; DDRE |= 1 << PE6;
  LCD_Init();
  DDRE &= ~(1 << PE6); PORTE &= ~(1 << PE6);
@z

@x
      PORTE |= 1 << PE6; /* base station on */
@y
@z

@x
        PORTE &= ~(1 << PE6); /* base station off */
        keydetect = 0; /* in case key was detected right before base station was
                          switched off, which means that nothing must come from it */
@y
@z

@x
    @<Check phone line state@>@;
    if (keydetect) {
      keydetect = 0;
      switch (PINB & (1 << PB4 | 1 << PB5 | 1 << PB6) | PIND & 1 << PD7) {
      case (0x10): digit = '1'; @+ break;
      case (0x20): digit = '2'; @+ break;
      case (0x30): digit = '3'; @+ break;
      case (0x40): digit = '4'; @+ break;
      case (0x50): digit = '5'; @+ break;
      case (0x60): digit = '6'; @+ break;
      case (0x70): digit = '7'; @+ break;
      case (0x80): digit = '8'; @+ break;
      case (0x90): digit = '9'; @+ break;
      case (0xA0): digit = '0'; @+ break;
      case (0xB0): digit = '*'; @+ break;
      case (0xC0): digit = '#'; @+ break;
      }
      while (!(UEINTX & 1 << TXINI)) ;
      UEINTX &= ~(1 << TXINI);
      UEDATX = digit;
      UEINTX &= ~(1 << FIFOCON);
    }
@y
    if (UEINTX & 1 << RXOUTI) {
      UEINTX &= ~(1 << RXOUTI);
      int rx_counter = UEBCLX;
      if (rx_counter != 8) PORTD |= 1 << PD5; /* proof check (this cannot happen) */
      PORTE |= 1 << PE6; DDRE |= 1 << PE6;
      LCD_Command(0x80);
      DDRE &= ~(1 << PE6); PORTE &= ~(1 << PE6);
      while (rx_counter--)
        LCD_Char(UEDATX);
      UEINTX &= ~(1 << FIFOCON);
    }
@z

@x
UENUM = EP1; /* restore */
@y
UENUM = EP2; /* restore */
@z
