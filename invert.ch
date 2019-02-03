@x
      if (rx_counter != 8) PORTD |= 1 << PD5; /* proof check (this cannot happen) */
@y
      if (rx_counter != 8) PORTD &= ~(1 << PD5); /* proof check (this cannot happen) */
@z
