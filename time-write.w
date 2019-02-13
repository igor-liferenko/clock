@* Intro.

This program runs on USB-host.

As serial port is done via USB, it appears and disappears dynamically;
to cope with this, connect is attempted in a loop and write status
is checked and |close| is called on serial port descriptor if necessary.

@d serial_port_closed() comfd == -1
@d serial_port_opened() comfd != -1

@c
@<Header files@>@/ /* FIXME: see @/ vs @; in cwebman */

void main(void)
{
  int comfd = -1;
  while (1) {
    if (serial_port_closed())
      @<Try to open serial port@>@;
    if (serial_port_opened())
      @<Write time to serial port@>@;
    sleep(1);
  }
}

@ @<Try to open serial port@>= {
  if ((comfd = open("/dev/ttyACM0", O_RDWR | O_NOCTTY)) != -1) {
    struct termios com_tty;
    tcgetattr(comfd, &com_tty);
    cfmakeraw(&com_tty);
    tcsetattr(comfd, TCSANOW, &com_tty);
    int DTR_bit = TIOCM_DTR;
    ioctl(comfd, TIOCMBIS, &DTR_bit);
  }
}

@ @<Write time to serial port@>= {
  time_t now = time(NULL);
  if (write(comfd, ctime(&now) + 11, 8) == -1) {
    close(comfd);
    comfd = -1;
  }
}

@ @<Header files@>=
#include <fcntl.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>
