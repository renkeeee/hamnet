//
//  NSData+Brotli.mm
//  NSData+Brotli
//
//  Created by Matthew Cheok on 9/24/15.
//  Copyright (c) 2015 Matthew Cheok. All rights reserved.
//

#import "NSData+Brotli.h"
#import "decode.h"
#import "encode.h"
#import "streams.h"

@implementation NSData (Brotli)

- (NSData *)br_compressedData {
  return [self br_compressedDataWithQuality:11];
}

- (NSData *)br_compressedDataWithQuality:(NSUInteger)quality {
  brotli::BrotliParams params;
  params.quality = (int)quality;

  uint8_t* compressedBuffer = (uint8_t*)malloc(self.length * sizeof(uint8_t));
  size_t compressedSize = self.length;

  if (!brotli::BrotliCompressBuffer(params,
                                    (size_t)self.length,
                                    (uint8_t*)self.bytes,
                                    &compressedSize,
                                    compressedBuffer)) {
    return nil;
  }

  NSData *data = [NSData dataWithBytes:compressedBuffer length:compressedSize];
  free(compressedBuffer);
  return data;
}

- (NSData *)br_decompressedData {
  size_t decodedSize = 0;
  if (!BrotliDecompressedSize((size_t)self.length,
                              (uint8_t*)self.bytes,
                              &decodedSize)) {
    return nil;
  }

  uint8_t* decompressedBuffer = (uint8_t*)malloc(decodedSize * sizeof(uint8_t));
  if (!BrotliDecompressBuffer((size_t)self.length,
                              (uint8_t*)self.bytes,
                              &decodedSize,
                              decompressedBuffer)) {
    return nil;
  }

  NSData *data = [NSData dataWithBytes:decompressedBuffer length:decodedSize];
  free(decompressedBuffer);
  return data;
}

@end
