# cython: language_level=3
from cython import cdivision
from libc.string cimport strlen, memcpy
from libc.stdio cimport FILE, fopen, fread, fwrite, fclose
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from . cimport api
from .control cimport SKP_SILK_SDK_EncControlStruct
from . cimport bytebuffer
# cdef extern from "src/Encoder.h":
#     int encode_file(
#         const char* speechInFileName,
#         const char* bitOutFileName,
#         int API_fs_Hz, # 24000
#         int max_internal_fs_Hz, # 0
#         int packetSize_ms, # 20
#         int targetRate_bps, # 25000
#         int packetLoss_perc, # 0
#         int complexity_mode, # 2
#         int INBandFEC_enabled, # 0
#         int DTX_enabled, # 0
#         int tencent, # 0
#         int quiet) # 1

cdef void swap_endian(
        short vec[],  #  I/O array of */
        int len):  #  I   length      */
    cdef:
        int i
        short tmp
        unsigned char*p1, *p2

    for i in range(len):
        tmp = vec[i]
        p1 = <unsigned char *> &vec[i]
        p2 = <unsigned char *> &tmp
        p1[0] = p2[1]
        p1[1] = p2[0]


class EncodeException(Exception):
    pass


cdef class Transcoder:
    def __init__(self):
        pass

    @cdivision(True)
    cpdef encode_file(self,
                      str input_file_name,
                      str output_file_name,
                      int API_fs_Hz=24000,
                      int max_internal_fs_Hz=0,
                      int packetSize_ms=20,
                      int targetRate_bps=25000,
                      int packetLoss_perc=0,
                      int complexity_mode=2,
                      bint INBandFEC_enabled=0,  # 0
                      bint DTX_enabled=0,
                      bint tencent=0,
                      bint byteorder=0,  # 0 little 1 big
                      bint low_complexity_only=0,
                      int max_bytes_per_frame=250,
                      int max_input_frames=5,
                      int max_api_fs_khz=48,
                      int frame_length_ms=20,
                      bint quiet=0):

        input_file_name_byte = input_file_name.encode("utf-8")
        output_file_name_byte = output_file_name.encode("utf-8")
        cdef:
            # char*speechInFileName = input_file_name.encode("utf-8")
            char*speechInFileName = input_file_name_byte
            # char*bitOutFileName = output_file_name.encode("utf-8")
            char*bitOutFileName = output_file_name_byte

            unsigned long tottime = 0, starttime

            double filetime
            size_t counter
            int k, totPackets = 0, totActPackets = 0, ret
            short nBytes;
            double sumBytes = 0.0, sumActBytes = 0.0, avg_rate, act_rate, nrg
            # unsigned char payload[max_bytes_per_frame * max_input_frames]
            unsigned char*payload = <unsigned char*> PyMem_Malloc(max_bytes_per_frame * max_input_frames)
            # short in_[frame_length_ms * max_api_fs_khz * max_input_frames]
            short*in_ = <short*> PyMem_Malloc(frame_length_ms * max_api_fs_khz * max_input_frames)
            FILE*bitOutFile, *speechInFile
            int encSizeBytes
            void*psEnc
            int smplsSinceLastPacket = 0
            int frameSizeReadFromFile_ms = 20

            SKP_SILK_SDK_EncControlStruct encControl
            SKP_SILK_SDK_EncControlStruct encStatus
            short nBytes_LE
            unsigned char Tencent_break = 0x02
        if not in_ or not payload:
            raise MemoryError()

        if low_complexity_only:
            complexity_mode = 0

        if max_internal_fs_Hz == 0:
            max_internal_fs_Hz = 24000
            if API_fs_Hz < max_internal_fs_Hz:
                max_internal_fs_Hz = API_fs_Hz

        speechInFile = fopen(speechInFileName, "rb")
        if not speechInFile:
            raise FileNotFoundError(f"could not open input file {speechInFileName}")

        bitOutFile = fopen(bitOutFileName, "wb")
        if not bitOutFile:
            raise FileNotFoundError(f"could not open input file {bitOutFileName}")

        if tencent:
            # cdef const unsigned char Tencent_break = 0x02
            fwrite(&Tencent_break, sizeof(char), 1, bitOutFile)
        cdef const char*Silk_header = "#!SILK_V3"
        fwrite(Silk_header, sizeof(char), strlen(Silk_header), bitOutFile)
        ret = api.SKP_Silk_SDK_Get_Encoder_Size(&encSizeBytes)
        if ret:
            raise EncodeException(f"SKP_Silk_create_encoder returned {ret}")

        psEnc = PyMem_Malloc(encSizeBytes)
        ret = api.SKP_Silk_SDK_InitEncoder(psEnc, &encStatus)
        if ret:
            raise EncodeException(f"SKP_Silk_reset_encoder returned {ret}")

        encControl.API_sampleRate = API_fs_Hz
        encControl.maxInternalSampleRate = max_internal_fs_Hz
        encControl.packetSize = (packetSize_ms * API_fs_Hz) / 1000
        encControl.packetLossPercentage = packetLoss_perc
        encControl.useInBandFEC = INBandFEC_enabled
        encControl.useDTX = DTX_enabled
        encControl.complexity = complexity_mode
        encControl.bitRate = targetRate_bps

        if API_fs_Hz > max_api_fs_khz * 1000 or API_fs_Hz < 0:
            raise EncodeException(f"API sampling rate = {API_fs_Hz} out of range, valid range 8000 - 48000")

        while True:
            counter = fread(in_, 2, (frameSizeReadFromFile_ms * API_fs_Hz) / 1000, speechInFile)
            if byteorder:
                swap_endian(in_, counter)
            if <int> counter < ((frameSizeReadFromFile_ms * API_fs_Hz) / 1000):
                break
            nBytes = max_bytes_per_frame * max_input_frames

            ret = api.SKP_Silk_SDK_Encode(psEnc, &encControl, in_, <short> counter, payload, &nBytes)
            if ret:
                raise EncodeException(f"SKP_Silk_Encode returned {ret}")
            # Get packet size
            packetSize_ms = <int> ((1000 * <int> encControl.packetSize) / encControl.API_sampleRate)
            smplsSinceLastPacket += <int> counter
            if ((1000 * smplsSinceLastPacket) / API_fs_Hz) == packetSize_ms:
                totPackets += 1
                sumBytes += nBytes
                nrg = 0.0
                for k in range(counter):
                    nrg += in_[k] * <double> in_[k]
                if (nrg / <int> counter) > 1e3:
                    sumActBytes += nBytes
                    totActPackets += 1
                if byteorder:
                    nBytes_LE = nBytes
                    swap_endian(&nBytes_LE, 1)
                    fwrite(&nBytes_LE, 2, 1, bitOutFile)
                else:
                    fwrite(&nBytes, 2, 1, bitOutFile)
                fwrite(payload, 1, nBytes, bitOutFile)
                smplsSinceLastPacket = 0
                # totPackets 可以返回
        nBytes = -1
        if not tencent:
            fwrite(&nBytes, 2, 1, bitOutFile)
        PyMem_Free(psEnc)
        PyMem_Free(in_)
        PyMem_Free(payload)
        fclose(speechInFile)
        fclose(bitOutFile)
        return totPackets

        # input_file_name_byte = input_file_name.encode("utf-8")
        # output_file_name_byte = output_file_name.encode("utf-8")
        #
        # encode_file(input_file_name_byte,output_file_name_byte,API_fs_Hz,max_internal_fs_Hz,packetSize_ms,)
    cpdef decode_file(self):
        pass

    cpdef bytes encode(self,
                       bytes input_data,
                       int API_fs_Hz=24000,
                       int max_internal_fs_Hz=0,
                       int packetSize_ms=20,
                       int targetRate_bps=25000,
                       int packetLoss_perc=0,
                       int complexity_mode=2,
                       bint INBandFEC_enabled=0,  # 0
                       bint DTX_enabled=0,
                       bint tencent=0,
                       bint byteorder=0,  # 0 little 1 big
                       bint low_complexity_only=0,
                       int max_bytes_per_frame=250,
                       int max_input_frames=5,
                       int max_api_fs_khz=48,
                       int frame_length_ms=20,
                       bint quiet=0):
        cdef:
            unsigned char flag
            unsigned long tottime = 0, starttime

            double filetime
            size_t counter
            int k, totPackets = 0, totActPackets = 0, ret
            short nBytes;
            double sumBytes = 0.0, sumActBytes = 0.0, avg_rate, act_rate, nrg
            # unsigned char payload[max_bytes_per_frame * max_input_frames]
            unsigned char*payload = <unsigned char*> PyMem_Malloc(max_bytes_per_frame * max_input_frames)
            # short in_[frame_length_ms * max_api_fs_khz * max_input_frames]
            short*in_ = <short*> PyMem_Malloc(frame_length_ms * max_api_fs_khz * max_input_frames)
            # FILE*bitOutFile, *speechInFile
            bytebuffer.Bytebuffer* bitOutFile=bytebuffer.Bytebuffer_New(100,&flag)
            bytebuffer.Bytebuffer* speechInFile = bytebuffer.Bytebuffer_New(100, &flag) # todo memory check and  init
            int encSizeBytes
            void*psEnc
            int smplsSinceLastPacket = 0
            int frameSizeReadFromFile_ms = 20

            SKP_SILK_SDK_EncControlStruct encControl
            SKP_SILK_SDK_EncControlStruct encStatus
            short nBytes_LE
            unsigned char Tencent_break = 0x02
        if not in_ or not payload:
            raise MemoryError()

        if low_complexity_only:
            complexity_mode = 0

        if max_internal_fs_Hz == 0:
            max_internal_fs_Hz = 24000
            if API_fs_Hz < max_internal_fs_Hz:
                max_internal_fs_Hz = API_fs_Hz

        if tencent:
            # cdef const unsigned char Tencent_break = 0x02
            fwrite(&Tencent_break, sizeof(char), 1, bitOutFile)
        cdef const char*Silk_header = "#!SILK_V3"
        fwrite(Silk_header, sizeof(char), strlen(Silk_header), bitOutFile)
        ret = api.SKP_Silk_SDK_Get_Encoder_Size(&encSizeBytes)
        if ret:
            raise EncodeException(f"SKP_Silk_create_encoder returned {ret}")

        psEnc = PyMem_Malloc(encSizeBytes)
        ret = api.SKP_Silk_SDK_InitEncoder(psEnc, &encStatus)
        if ret:
            raise EncodeException(f"SKP_Silk_reset_encoder returned {ret}")

        encControl.API_sampleRate = API_fs_Hz
        encControl.maxInternalSampleRate = max_internal_fs_Hz
        encControl.packetSize = (packetSize_ms * API_fs_Hz) / 1000
        encControl.packetLossPercentage = packetLoss_perc
        encControl.useInBandFEC = INBandFEC_enabled
        encControl.useDTX = DTX_enabled
        encControl.complexity = complexity_mode
        encControl.bitRate = targetRate_bps

        if API_fs_Hz > max_api_fs_khz * 1000 or API_fs_Hz < 0:
            raise EncodeException(f"API sampling rate = {API_fs_Hz} out of range, valid range 8000 - 48000")

        while True:
            counter = fread(in_, 2, (frameSizeReadFromFile_ms * API_fs_Hz) / 1000, speechInFile) # memcpy
            if byteorder:
                swap_endian(in_, counter)
            if <int> counter < ((frameSizeReadFromFile_ms * API_fs_Hz) / 1000):
                break
            nBytes = max_bytes_per_frame * max_input_frames

            ret = api.SKP_Silk_SDK_Encode(psEnc, &encControl, in_, <short> counter, payload, &nBytes)
            if ret:
                raise EncodeException(f"SKP_Silk_Encode returned {ret}")
            # Get packet size
            packetSize_ms = <int> ((1000 * <int> encControl.packetSize) / encControl.API_sampleRate)
            smplsSinceLastPacket += <int> counter
            if ((1000 * smplsSinceLastPacket) / API_fs_Hz) == packetSize_ms:
                totPackets += 1
                sumBytes += nBytes
                nrg = 0.0
                for k in range(counter):
                    nrg += in_[k] * <double> in_[k]
                if (nrg / <int> counter) > 1e3:
                    sumActBytes += nBytes
                    totActPackets += 1
                if byteorder:
                    nBytes_LE = nBytes
                    swap_endian(&nBytes_LE, 1)
                    fwrite(&nBytes_LE, 2, 1, bitOutFile)
                else:
                    fwrite(&nBytes, 2, 1, bitOutFile)
                fwrite(payload, 1, nBytes, bitOutFile)
                smplsSinceLastPacket = 0
                # totPackets 可以返回
        nBytes = -1
        if not tencent:
            fwrite(&nBytes, 2, 1, bitOutFile)
        PyMem_Free(psEnc)
        PyMem_Free(in_)
        PyMem_Free(payload)
        fclose(speechInFile)
        fclose(bitOutFile)
        return totPackets

    cpdef decode(self):
        pass
