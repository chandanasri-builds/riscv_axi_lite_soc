volatile unsigned int * const UART_TX = (volatile unsigned int *)0x10000000;

void main(void)
{
    *UART_TX = 0x41;   // 'A'

    while (1) {
    }
}
