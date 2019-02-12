@* Intro.

This program runs on USB-host.

As serial port is done via USB, it appears and disappears dynamically;
to cope with this, connect is attempted in a loop and write status
is checked and port is closed if necessary in signal handler.

When the handler for the signal is invoked, that signal is automatically
blocked until the handler returns. We need not the signal be delivered after
the handler returns (just in case the handler takes too long to execute),
so we disable signal handler inside signal handler.

The signal may arrive only during |pause|,
so |localtime|, used by |ctime|, which is not signal-safe, may be used in
signal handler.

According to signal(2), using |signal| is allowed
with |SIG_IGN|.

@c
#include <fcntl.h> 
#include <signal.h>
#include <sys/ioctl.h> 
#include <sys/time.h>
#include <termios.h> 
#include <time.h> 
#include <unistd.h> 

struct sigaction sa;
volatile int comfd = -1;

void my_write(int signum)
{
  if (comfd == -1) return;
  signal(SIGALRM, SIG_IGN);
  time_t now = time(NULL);
  if (write(comfd, ctime(&now) + 11, 8) == -1) {
    close(comfd);
    comfd = -1;
  }
  sigaction(SIGALRM, &sa, NULL);
}

void main(void)
{
  sa.sa_handler = my_write;

  signal(SIGALRM, SIG_IGN); /* default terminates the process */

  struct itimerval tv;
  tv.it_value.tv_sec = 1;
  tv.it_value.tv_usec = 0;
  tv.it_interval.tv_sec = 1; /* when timer expires, reset to 1s */
  tv.it_interval.tv_usec = 0;
  setitimer(ITIMER_REAL, &tv, NULL);

  while (1) {
    if (comfd == -1) {
      signal(SIGALRM, SIG_IGN);
      if ((comfd = open("/dev/ttyACM0", O_RDWR | O_NOCTTY)) != -1) {
        struct termios com_tty;
        tcgetattr(comfd, &com_tty);
        cfmakeraw(&com_tty);
        tcsetattr(comfd, TCSANOW, &com_tty);
        int DTR_bit = TIOCM_DTR;
        ioctl(comfd, TIOCMBIS, &DTR_bit);
      }
      sigaction(SIGALRM, &sa, NULL);
    }
    pause(); /* sleep until timer expires */
  }
}
