//
// Created by jhc on 2021/2/12.
//

#ifndef TEA_ENCODER_H
#define TEA_ENCODER_H

#include "SKP_Silk_SDK_API.h"
int encode_file(
        const char* speechInFileName,
        const char* bitOutFileName,
        SKP_int32 API_fs_Hz, // 24000
        SKP_int32 max_internal_fs_Hz, // 0
        SKP_int32 packetSize_ms, // 20
        SKP_int32 targetRate_bps, // 25000
        SKP_int32 packetLoss_perc, // 0
        SKP_int32 complexity_mode, // 2
        SKP_int32 INBandFEC_enabled, // 0
        SKP_int32 DTX_enabled, // 0
        SKP_int32 tencent, // 0
        SKP_int32 quiet) // 0

#endif //TEA_ENCODER_H
