@ @c
@<Header files@>@;

@<Global variables@>@;

int main(void)
{
  @<Set external encoding@>@;
  @<Open com-port@>@;
  char str[100];
  while (1) {
    time_t now = time(NULL);
//TODO: use code from "watch -n1"
    sprintf(str, "%.*s", 8, ctime(&now) + 11);
    if (write(comfd, str, 8) == -1) {
      close(comfd);
      @<Reopen com-port@>@;
    }
  }
}

@** COM-port setup.
|comfd| contains file descriptor for com-port.

@<Global...@>=
int comfd;
int DTR_bit = TIOCM_DTR; /* |DTR| line */

@ @d COM_PORT "/dev/ttyACM0"

@<Open com-port@>=
if ((comfd = open(COM_PORT, O_RDWR | O_NOCTTY)) == -1) {
  fwprintf(stderr, L"ERR: terminal is not connected\n");
  @<Reopen com-port@>@;
}
else {
  fwprintf(stderr, L"INF: connected terminal\n");
  @<Save tty...@>@;
  @<Set tty settings@>@;
  @<Put |DTR| line to high state@>@;
}

@ @<Reopen com-port@>=
while ((comfd = open(COM_PORT, O_RDWR | O_NOCTTY)) == -1)
  sleep(1);
fwprintf(stderr, L"INF: terminal appeared\n");
@<Save tty settings@>@; /* FIXME: probably no need to do this, because we did
  this on program start */
@<Set tty settings@>@;
@<Put |DTR| line to high state@>@;

@ @<Global...@>=
struct termios com_tty_restore;

@ @<Save tty...@>=
tcgetattr(comfd, &com_tty_restore);

@ @<Global...@>=
struct termios com_tty;

@ @<Set tty...@>=
tcgetattr(comfd, &com_tty);
cfmakeraw(&com_tty);
tcsetattr(comfd, TCSANOW, &com_tty);

@ @<Close...@>=
tcsetattr(comfd, TCSANOW, &com_tty_restore);
close(comfd);

@ @<Put |DTR| line to high state@>=
ioctl(comfd, TIOCMBIS, &DTR_bit); /* set |DTR| */

@ @<Put |DTR| line to low state@>=
ioctl(comfd, TIOCMBIC, &DTR_bit); /* clear |DTR| */

@ @<Set external...@>=
setlocale(LC_CTYPE, "C.UTF-8");

@ @<Header...@>=
#include <errno.h> /* |errno|, |ECONNRESET| */
#include <termios.h> /* |struct termios|, |tcgetattr|, |tcsetattr|, |TCSANOW|,
  |cfmakeraw|, |TIOCM_DTR|, |tcflush| */
#include <locale.h> /* |setlocale|, |LC_CTYPE| */
#include <wchar.h> /* |fwprintf|, |fgetws| */
#include <fcntl.h> /* |open|, |O_RDONLY| */
#include <unistd.h> /* |read|, |close|, |STDOUT_FILENO|, |pid_t| */
#include <stdio.h> /* |stdout|, |stderr| */
#include <stdlib.h> /* |exit|, |EXIT_SUCCESS|, |EXIT_FAILURE|, |rand|, |srand| */
#include <sys/ioctl.h> /* |ioctl|, |TIOCMBIS|, |TIOCMBIC| */
#include <sys/wait.h> /* |waitpid| */
#include <time.h> /* |time| */
#include <netinet/in.h> /* |IPPROTO_IP| */
#include <sys/socket.h> /* |accept|, |socket|, |bind|, |listen|, |AF_INET|,
  |SOCK_STREAM|, |SOMAXCONN| */
#include <stdarg.h> /* |va_start|, |va_end|, |va_list| */
#include <arpa/inet.h> /* |htons| */
