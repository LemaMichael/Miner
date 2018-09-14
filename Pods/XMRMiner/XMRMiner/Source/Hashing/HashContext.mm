//
//  HashContext.m
//  XMRMiner
//
//  Created by Nick Lee on 10/12/17.
//

#import "HashContext.h"
#import "../../Vendor/crypto/cryptonight.h"

@interface HashContext()

@property (nonatomic, readonly) struct cryptonight_ctx *ctx;

@end

@implementation HashContext



- (instancetype)init
{
    if (self = [super init]) {
        _ctx = (struct cryptonight_ctx*)malloc(sizeof(struct cryptonight_ctx));
    }
    return self;
}
    
- (void)dealloc
{
    if (_ctx) {
        free(_ctx);
        _ctx = NULL;
    }
}

- (NSData * _Nonnull)hashData:(NSData * _Nonnull)data
{
    NSMutableData *output = [NSMutableData dataWithLength:32];
    cryptonight_hash_ctx(output.mutableBytes, data.bytes, self.ctx);
    return output;
}

@end
