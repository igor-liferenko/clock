@* Intro.

Serial port is done via USB, so it appears and disappears dynamically;
to cope with this, connect is attempted in a loop and write status
is checked and port is closed if necessary in signal handler.

@c
#include <fcntl.h> 
#include <signal.h>
#include <sys/ioctl.h> 
#include <sys/time.h>
#include <termios.h> 
#include <time.h> 
#include <unistd.h> 

volatile int comfd = -1;
void my_write(int signum) /* it is expected that this handler runs in less that 1 second;
  not signal-safe function is used here, so for stable operation you may need to cancel
  the signal (no block, because we need not the signal be delivered after unblock)
  while the handler is executing - think how to do it */
{
  if (comfd == -1) return;
  time_t now = time(NULL);
  if (write(comfd, ctime(&now) + 11, 8) == -1) { /* signal may arrive only during |pause|,
    so |localtime|, used by |ctime|, which is not signal-safe, may be used here */
    close(comfd);
    comfd = -1;
  }
}

int main(void)
{
  struct itimerval tv;
  tv.it_value.tv_sec = 1;
  tv.it_value.tv_usec = 0;
  tv.it_interval.tv_sec = 1; /* when timer expires, reset to 1s */
  tv.it_interval.tv_usec = 0;
  setitimer(ITIMER_REAL, &tv, NULL); /* it is unlikely that |signal| will not be called
    within 1 second after setting the timer, so it is not necessary to call |signal| before
    setting the timer */

  struct sigaction sa;
  sa.sa_handler = my_write;

  while (1) {
    if (comfd == -1) {
      signal(SIGALRM, SIG_IGN); /* according to signal(2), using |signal| is allowed
        in this case */
      if ((comfd = open("/dev/ttyACM0", O_RDWR | O_NOCTTY)) != -1) {
        struct termios com_tty;
        tcgetattr(comfd, &com_tty);
        cfmakeraw(&com_tty);
        tcsetattr(comfd, TCSANOW, &com_tty);
        int DTR_bit = TIOCM_DTR;
        ioctl(comfd, TIOCMBIS, &DTR_bit);
      }
      sigaction(SIGALRM, &sa, NULL); /* (re)enable signal handler */
    }
    pause();
  }
}
