
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "keccak.h"
#include "blake.h"
#include "skein.h"
#include "jh/jh.h"
#include "groestl.h"
#include "cryptonight.h"
#include "aesb.h"

void do_blake_hash(const void* input, size_t len, char* output) {
    blake(input, len, (unsigned char *)output);
}

void do_groestl_hash(const void* input, size_t len, char* output) {
    groestl(input, len * 8, (uint8_t*)output);
}

void do_jh_hash(const void* input, size_t len, char* output) {
    jh(32 * 8, input, 8 * len, (uint8_t*)output);
}

void do_skein_hash(const void* input, size_t len, char* output) {
    skein(8 * 32, input, 8 * len, (uint8_t*)output);
}

void (* const extra_hashes[4])(const void *, size_t, char *) = {
	do_blake_hash, do_groestl_hash, do_jh_hash, do_skein_hash};

void xor_blocks_dst(const uint8_t * a, const uint8_t * b, uint8_t * dst) {
    ((uint64_t*) dst)[0] = ((uint64_t*) a)[0] ^ ((uint64_t*) b)[0];
    ((uint64_t*) dst)[1] = ((uint64_t*) a)[1] ^ ((uint64_t*) b)[1];
}

// Credit to Wolf for optimizing this function
static inline size_t e2i(const uint8_t* a) {
    return ((uint32_t *)a)[0] & 0x1FFFF0;
}

static inline uint64_t mul128(uint64_t multiplier, uint64_t multiplicand, uint64_t *product_hi)
{
  // multiplier   = ab = a * 2^32 + b
  // multiplicand = cd = c * 2^32 + d
  // ab * cd = a * c * 2^64 + (a * d + b * c) * 2^32 + b * d
  uint64_t a = multiplier >> 32;
  uint64_t b = multiplier & 0xFFFFFFFF;
  uint64_t c = multiplicand >> 32;
  uint64_t d = multiplicand & 0xFFFFFFFF;

  //uint64_t ac = a * c;
  uint64_t ad = a * d;
  //uint64_t bc = b * c;
  uint64_t bd = b * d;

  uint64_t adbc = ad + (b * c);
  uint64_t adbc_carry = adbc < ad ? 1 : 0;

  // multiplier * multiplicand = product_hi * 2^64 + product_lo
  uint64_t product_lo = bd + (adbc << 32);
  uint64_t product_lo_carry = product_lo < bd ? 1 : 0;
  *product_hi = (a * c) + (adbc >> 32) + (adbc_carry << 32) + product_lo_carry;
  //assert(ac <= *product_hi);

  return product_lo;
}

static inline void mul_sum_xor_dst(const uint8_t *a, uint8_t *c, uint8_t *dst)
{
    uint64_t hi, lo = mul128(((uint64_t *)a)[0], ((uint64_t *)dst)[0], &hi) + ((uint64_t *)c)[1];
	hi += ((uint64_t *)c)[0];
	
    ((uint64_t *)c)[0] = ((uint64_t*) dst)[0] ^ hi;
    ((uint64_t *)c)[1] = ((uint64_t*) dst)[1] ^ lo;
    ((uint64_t *)dst)[0] = hi;
    ((uint64_t *)dst)[1] = lo;
}

static inline void xor_blocks(uint8_t * a, const uint8_t * b) {
    ((uint64_t*) a)[0] ^= ((uint64_t*) b)[0];
    ((uint64_t*) a)[1] ^= ((uint64_t*) b)[1];
}

typedef uint32_t vec4u32 __attribute__ ((vector_size(16)));

void cryptonight_hash_ctx(void * output, const void * input, struct cryptonight_ctx * ctx) {
    ctx->aes_ctx = (oaes_ctx*) oaes_alloc();
    size_t i, j;
    //hash_process(&ctx->state.hs, (const uint8_t*) input, 76);
    keccak((const uint8_t *)input, 76, ctx->state.hs.b, 200);
    memcpy(ctx->text, ctx->state.init, INIT_SIZE_BYTE);
    
    oaes_key_import_data(ctx->aes_ctx, ctx->state.hs.b, AES_KEY_SIZE);

    for(i = 0; likely(i < MEMORY); i += INIT_SIZE_BYTE)
    {
//        for(j = 0; j < 10; j++)
//        {
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0],    (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x10], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x20], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x30], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x40], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x50], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x60], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x70], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//        }
//        memcpy(&ctx->long_state[i], ctx->text, INIT_SIZE_BYTE);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 0], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 1], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 2], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 3], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 4], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 5], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 6], ctx->aes_ctx->key->exp_data);
        aesb_pseudo_round_mut(&ctx->text[AES_BLOCK_SIZE * 7], ctx->aes_ctx->key->exp_data);
        memcpy(&ctx->long_state[i], ctx->text, INIT_SIZE_BYTE);
	}
	
	for (i = 0; i < 2; i++) 
    {
	    ((uint64_t *)(ctx->a))[i] = ((uint64_t *)ctx->state.k)[i] ^  ((uint64_t *)ctx->state.k)[i+4];
	    ((uint64_t *)(ctx->b))[i] = ((uint64_t *)ctx->state.k)[i+2] ^  ((uint64_t *)ctx->state.k)[i+6];
    }
	
    //xor_blocks_dst(&ctx->state.k[0], &ctx->state.k[32], ctx->a);
    //xor_blocks_dst(&ctx->state.k[16], &ctx->state.k[48], ctx->b);

    for (i = 0; likely(i < ITER / 4); ++i) {
//        // Dependency chain: address -> read value ------+
//        // written value <-+ hard function (AES or MUL) <+
//        // next address  <-+
//        //
//        // Iteration 1
//        SubAndShiftAndMixAddRound((uint32_t *)ctx->c, (uint32_t *)&ctx->long_state[((uint64_t *)(ctx->a))[0] & 0x1FFFF0], (uint32_t *)ctx->a);
//        xor_blocks_dst(ctx->c, ctx->b, &ctx->long_state[((uint64_t *)(ctx->a))[0] & 0x1FFFF0]);
//        // Iteration 2
//        mul_sum_xor_dst(ctx->c, ctx->a, &ctx->long_state[((uint64_t *)(ctx->c))[0] & 0x1FFFF0]);
//        // Iteration 3
//        SubAndShiftAndMixAddRound((uint32_t *)ctx->b, (uint32_t *)&ctx->long_state[((uint64_t *)(ctx->a))[0] & 0x1FFFF0], (uint32_t *)ctx->a);
//        xor_blocks_dst(ctx->b, ctx->c, &ctx->long_state[((uint64_t *)(ctx->a))[0] & 0x1FFFF0]);
//        // Iteration 4
//        mul_sum_xor_dst(ctx->b, ctx->a, &ctx->long_state[((uint64_t *)(ctx->b))[0] & 0x1FFFF0]);
        /* Dependency chain: address -> read value ------+
         * written value <-+ hard function (AES or MUL) <+
         * next address  <-+
         */
        /* Iteration 1 */
        j = e2i(ctx->a);
        aesb_single_round(&ctx->long_state[j], ctx->c, ctx->a);
        xor_blocks_dst(ctx->c, ctx->b, &ctx->long_state[j]);
        /* Iteration 2 */
        mul_sum_xor_dst(ctx->c, ctx->a, &ctx->long_state[e2i(ctx->c)]);
        /* Iteration 3 */
        j = e2i(ctx->a);
        aesb_single_round(&ctx->long_state[j], ctx->b, ctx->a);
        xor_blocks_dst(ctx->b, ctx->c, &ctx->long_state[j]);
        /* Iteration 4 */
        mul_sum_xor_dst(ctx->b, ctx->a, &ctx->long_state[e2i(ctx->b)]);
    }

    memcpy(ctx->text, ctx->state.init, INIT_SIZE_BYTE);

    oaes_free((OAES_CTX **) &ctx->aes_ctx);
    ctx->aes_ctx = (oaes_ctx*) oaes_alloc();

    oaes_key_import_data(ctx->aes_ctx, &ctx->state.hs.b[32], AES_KEY_SIZE);
    
    for(i = 0; likely(i < MEMORY); i += INIT_SIZE_BYTE)
    {
//        xor_blocks(&ctx->text[0x00], &ctx->long_state[i + 0x00]);
//        xor_blocks(&ctx->text[0x10], &ctx->long_state[i + 0x10]);
//        xor_blocks(&ctx->text[0x20], &ctx->long_state[i + 0x20]);
//        xor_blocks(&ctx->text[0x30], &ctx->long_state[i + 0x30]);
//        xor_blocks(&ctx->text[0x40], &ctx->long_state[i + 0x40]);
//        xor_blocks(&ctx->text[0x50], &ctx->long_state[i + 0x50]);
//        xor_blocks(&ctx->text[0x60], &ctx->long_state[i + 0x60]);
//        xor_blocks(&ctx->text[0x70], &ctx->long_state[i + 0x70]);
//
//        for(j = 0; j < 10; j++)
//        {
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0],    (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x10], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x20], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x30], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x40], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x50], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x60], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//            SubAndShiftAndMixAddRoundInPlace((uint32_t *)&ctx->text[0x70], (uint32_t *)&ctx->aes_ctx->key->exp_data[j << 4]);
//        }
        
        xor_blocks(&ctx->text[0 * AES_BLOCK_SIZE], &ctx->long_state[i + 0 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[0 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[1 * AES_BLOCK_SIZE], &ctx->long_state[i + 1 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[1 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[2 * AES_BLOCK_SIZE], &ctx->long_state[i + 2 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[2 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[3 * AES_BLOCK_SIZE], &ctx->long_state[i + 3 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[3 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[4 * AES_BLOCK_SIZE], &ctx->long_state[i + 4 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[4 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[5 * AES_BLOCK_SIZE], &ctx->long_state[i + 5 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[5 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[6 * AES_BLOCK_SIZE], &ctx->long_state[i + 6 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[6 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        xor_blocks(&ctx->text[7 * AES_BLOCK_SIZE], &ctx->long_state[i + 7 * AES_BLOCK_SIZE]);
        aesb_pseudo_round_mut(&ctx->text[7 * AES_BLOCK_SIZE], ctx->aes_ctx->key->exp_data);
        
	}

		
    memcpy(ctx->state.init, ctx->text, INIT_SIZE_BYTE);
    //hash_permutation(&ctx->state.hs);
    keccakf((uint64_t *)ctx->state.hs.b, 24);
    /*memcpy(hash, &state, 32);*/
    extra_hashes[ctx->state.hs.b[0] & 3](&ctx->state, 200, output);
    oaes_free((OAES_CTX **) &ctx->aes_ctx);
}

void cryptonight(void* output, const void* input, size_t len) {
    struct cryptonight_ctx *ctx = (struct cryptonight_ctx*)malloc(sizeof(struct cryptonight_ctx));
    cryptonight_hash_ctx(output, input, ctx);
    free(ctx);
}
