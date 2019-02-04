@ @d COM_PORT "/dev/ttyACM0"

@c
@<Header files@>@;

int comfd;
int DTR_bit = TIOCM_DTR; /* |DTR| line */
struct termios com_tty_restore;
struct termios com_tty;

int main(void)
{
  @<Open com-port@>@;
  while (1) {
    time_t now = time(NULL);
    if (write(comfd, ctime(&now) + 11, 8) == -1) {
      close(comfd);
      @<Reopen com-port@>@;
      continue;
    }
    sleep(1); /* FIXME: use code from `\.{watch -n1}'? */
  }
}

@ @<Open com-port@>=
if ((comfd = open(COM_PORT, O_WRONLY | O_NOCTTY)) == -1) {
  @<Reopen com-port@>@;
}
else {
  tcgetattr(comfd, &com_tty);
  cfmakeraw(&com_tty);
  tcsetattr(comfd, TCSANOW, &com_tty);
  ioctl(comfd, TIOCMBIS, &DTR_bit); /* set |DTR| */
}

@ @<Reopen com-port@>=
while ((comfd = open(COM_PORT, O_WRONLY | O_NOCTTY)) == -1)
  sleep(1);
tcgetattr(comfd, &com_tty);
cfmakeraw(&com_tty);
tcsetattr(comfd, TCSANOW, &com_tty);
ioctl(comfd, TIOCMBIS, &DTR_bit); /* set |DTR| */

@ @<Header...@>=
#include <termios.h> /* |struct termios|, |tcgetattr|, |tcsetattr|, |TCSANOW|,
  |cfmakeraw|, |TIOCM_DTR| */
#include <fcntl.h> /* |open|, |O_WRONLY| */
#include <unistd.h> /* |close|, |write| */
#include <sys/ioctl.h> /* |ioctl|, |TIOCMBIS|, |TIOCMBIC| */
#include <time.h> /* |time| */
