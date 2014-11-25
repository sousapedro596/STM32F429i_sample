// from newlib_stubs.c

#include "stm32f4xx.h"
#include <sys/types.h>
#include <errno.h>

caddr_t _sbrk(int incr) {

	extern char _ebss; // Defined by the linker
	static char *heap_end;
	char *prev_heap_end;

	if (heap_end == 0) {
		heap_end = &_ebss;
	}
	prev_heap_end = heap_end;

	//todo: check consumtion
	//char * stack = (char*) __get_MSP();
	if (heap_end + incr >  (char*)0x2002FC00)
	{
		//_write (STDERR_FILENO, "Heap and stack collision\n", 25);
		errno = ENOMEM;
		return  (caddr_t) -1;
		//abort ();
	}

	heap_end += incr;
	return (caddr_t) prev_heap_end;

}

void _exit(void) {
	while(1) {
		// Loop until reset
	}
}

