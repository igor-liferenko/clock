NOTE: as we do not write anything to USB host, we may use non-patched 
cdc-acm driver (on raspberry pi openwrt)

We handle DTR here because it is automatically sent to device by driver on open()
('0' in patched cdc-acm driver and '1' in non-patched), otherwise \.{time-write.w} will be
blocked on open() for 5 sec.
TODO: check it via wireshark

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
  @<Set |PD2| to pullup mode@>@;
  EICRA |= 1 << ISC11 | 1 << ISC10; /* set INT1 to trigger on rising edge */
  EIMSK |= 1 << INT1; /* turn on INT1; if it happens while USB RESET interrupt
    is processed, it does not change anything, as the device is going to be reset;
    if USB RESET happens whiled this interrupt is processed, it also does not change
    anything, as USB RESET is repeated several times by USB host, so it is safe
    that USB RESET interrupt is enabled (we cannot disable it because USB host
    may be rebooted) */
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
    @<Check |PD2| and indicate it via |PD5| and if it changed write to USB `\.\@' or `\.\%'
      (the latter only if DTR)@>@;
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
@ We check if handset is in use by using a switch. The switch is
optocoupler.

TODO create avrtel.4 which merges PC817C.png and PC817C-pinout.png,
except pullup part, and put section "enable pullup" before this section
and "git rm PC817C.png PC817C-pinout.png"

For on-line indication we send `\.{@@}' character to \.{tel}---to put
it to initial state.
For off-line indication we send `\.{\%}' character to \.{tel}---to disable
power reset on base station after timeout.

$$\hbox to9cm{\vbox to5.93cm{\vfil\special{psfile=avrtel.4
  clip llx=0 lly=0 urx=663 ury=437 rwi=2551}}\hfil}$$

@<Check |PD2| and indicate it via |PD5| and if it changed write to USB `\.\@' or `\.\%'
  (the latter only if DTR)@>=
if (PIND & 1 << PD2) { /* off-line */
  if (PORTD & 1 << PD5) { /* transition happened */
    if (line_status.DTR) { /* off-line was not caused by un-powering base station */
      while (!(UEINTX & 1 << TXINI)) ;
      UEINTX &= ~(1 << TXINI);
      UEDATX = '%';
      UEINTX &= ~(1 << FIFOCON);
    }
  }
  PORTD &= ~(1 << PD5);
}
else { /* on-line */
  if (!(PORTD & 1 << PD5)) { /* transition happened */
    while (!(UEINTX & 1 << TXINI)) ;
    UEINTX &= ~(1 << TXINI);
    UEDATX = '@@';
    UEINTX &= ~(1 << FIFOCON);
  }
  PORTD |= 1 << PD5;
}

@ The pull-up resistor is connected to the high voltage (this is usually 3.3V or 5V and is
often refereed to as VCC).

Pull-ups are often used with buttons and switches.

With a pull-up resistor, the input pin will read a high state when the photo-transistor
is not opened. In other words, a small amount of current is flowing between VCC and the input
pin (not to ground), thus the input pin reads close to VCC. When the photo-transistor is
opened, it connects the input pin directly to ground. The current flows through the resistor
to ground, thus the input pin reads a low state.

Since pull-up resistors are so commonly needed, our MCU has internal pull-ups
that can be enabled and disabled.

$$\hbox to7.54cm{\vbox to3.98638888888889cm{\vfil\special{psfile=avrtel.2
  clip llx=0 lly=0 urx=214 ury=113 rwi=2140}}\hfil}$$

@<Set |PD2| to pullup mode@>=
PORTD |= 1 << PD2;
_delay_us(1); /* after enabling pullup, wait for the pin to settle before reading it */
@y
@z

@x
UENUM = EP1; /* restore */
@y
UENUM = EP2; /* restore */
@z

@x
@i ../usb/IN-endpoint-management.w
@y
@i ../usb/OUT-endpoint-management.w
@z
