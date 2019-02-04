@ @c
#include <fcntl.h> 
#include <sys/ioctl.h> 
#include <termios.h> 
#include <time.h> 
#include <unistd.h> 

int main(void)
{
  int comfd = -1;
  while (1) {
    if (comfd == -1) {
      while ((comfd = open("/dev/ttyACM0", O_RDWR | O_NOCTTY)) == -1)
        sleep(1);
      struct termios com_tty;
      tcgetattr(comfd, &com_tty);
      cfmakeraw(&com_tty);
      tcsetattr(comfd, TCSANOW, &com_tty);
      int DTR_bit = TIOCM_DTR;                 
      ioctl(comfd, TIOCMBIS, &DTR_bit);
    }
    time_t now = time(NULL);
    if (write(comfd, ctime(&now) + 11, 8) == -1) {
      close(comfd);
      comfd = -1;
      continue;
    }
    sleep(1);
  }
}
