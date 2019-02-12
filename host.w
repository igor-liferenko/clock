@* Intro.

Serial port is done via USB, so it appears and disappears dynamically;
to cope with this, status is always checked and (re)connect is constantly
attempted after a timeout.

ctime is equivalent to this:
time_t now = time(NULL);
struct tm *дата = localtime(&now);
if (год == (дата->tm_year + 1900) && месяц == (дата->tm_mon + 1) && день == дата->tm_mday) {
Read about signal safety of localtime in cdr-coral.w

@c
#include <fcntl.h> 
#include <signal.h>
#include <sys/ioctl.h> 
#include <sys/time.h>
#include <termios.h> 
#include <time.h> 
#include <unistd.h> 

volatile int comfd = -1;
void my_write(int signum)
{
  if (comfd == -1) return;
  time_t now = time(NULL);
  if (write(comfd, ctime(&now) + 11, 8) == -1) {
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

  struct sigaction psa;
  psa.sa_handler = my_write;

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
        sigaction(SIGALRM, &psa, NULL);
      }
    }
    sleep(1);
  }
}
