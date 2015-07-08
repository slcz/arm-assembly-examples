
#ifndef _SHA_H_
#define _SHA_H_

#define CTX_BUF 0
#define CTX_BSZ 64
#define CTX_STA 64
#define CTX_BIT 96
#define CTX_LEN 104
#define PAD 8

#ifndef __ASSEMBLY__
struct sha256_context {
	uint8_t  buf[64];
	uint32_t state[8];
	uint64_t bitlen;
	uint32_t datalen;
};
void     sha256_init(struct sha256_context *);
uint8_t *sha256_final(struct sha256_context *);
void     sha256_update(uint8_t *, uint32_t *);
#define sha256_progress(context, ch) do {                        \
	(context)->buf[(context)->datalen ++] = (ch);            \
	if ((context)->datalen == CTX_BSZ) {                     \
		sha256_update((context)->buf, (context)->state); \
		(context)->datalen = 0;                          \
		(context)->bitlen += CTX_BSZ * 8;                \
	}                                                        \
} while (0)
#endif

#endif /* _SHA_H_ */
