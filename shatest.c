
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include "sha.h"

int
main(void)
{
	struct sha256_context context;
	int c, i;
	uint8_t *p;

	sha256_init(&context);
	i = 0;
	while ((c = fgetc(stdin)) != EOF)
		sha256_progress(&context, c);
	p = sha256_final(&context);
	for (i = 0; i < 32; i ++)
		printf("%02x", p[i]);
	printf("\n");
}
