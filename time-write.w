@* Intro.

Serial port is done via USB, so it appears and disappears dynamically;
to cope with this, connect is attempted in a loop and write status
is checked and |close| is called on serial port descriptor if necessary.

TTY device file must not be created if it does not
already exist. This is similar to `\.{cat >}', but |open|
syscall is without |O_CREAT|.

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

@ @<Try to open serial port@>=
comfd = open("/dev/ttyACM0", O_WRONLY | O_NOCTTY);

@ @<Write time to serial port@>= {
  time_t now = time(NULL);
  if (write(comfd, ctime(&now) + 11, 8) == -1) {
    close(comfd);
    comfd = -1;
  }
}

@ @<Header files@>=
#include <fcntl.h>
#include <time.h>
#include <unistd.h>
