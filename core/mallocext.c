#include "stm32f4xx.h"
#include <sys/types.h>
#include <errno.h>

caddr_t sbrk_ext(int incr) {

	static char *heap_end;
	char *prev_heap_end;

	if (heap_end == 0) {
		heap_end = (char*)0xD0000000;
	}
	prev_heap_end = heap_end;

	//todo: check consumtion
	//char * stack = (char*) __get_MSP();
	if (heap_end + incr >  (char*)0xD0400000)
	{
		//_write (STDERR_FILENO, "Heap and stack collision\n", 25);
		errno = ENOMEM;
		return  (caddr_t) -1;
		//abort ();
	}

	heap_end += incr;
	return (caddr_t) prev_heap_end;

}

typedef struct free_block {
	size_t size;
	struct free_block* next;
} free_block;

static free_block free_block_list_head = { 0, 0 };

static const size_t align_to = 16;

void* malloc_ext(size_t size) {
	size = (size + sizeof(free_block) + (align_to - 1)) & ~ (align_to - 1);
	free_block* block = free_block_list_head.next;
	free_block** head = &(free_block_list_head.next);
	while (block != 0) {
		if (block->size >= size) {
			*head = block->next;
			return ((char*)block) + sizeof(free_block);
		}
		head = &(block->next);
		block = block->next;
	}

	block = (free_block*)sbrk_ext(size);
	block->size = size;

	return ((char*)block) + sizeof(free_block);
}

void free_ext(void* ptr) {
	free_block* block = (free_block*)(((char*)ptr) - sizeof(free_block ));
	block->next = free_block_list_head.next;
	free_block_list_head.next = block;
}
