# cython: language_level=3
from cython import cdivision
from libc.string cimport strlen, memcpy, strcmp, memmove
from libc.stdio cimport FILE, fopen, fread, fwrite, fclose
from cpython.mem cimport PyMem_Malloc, PyMem_Free

from .cimport api
from .control cimport SKP_SILK_SDK_EncControlStruct, SKP_SILK_SDK_DecControlStruct
from .Decoder cimport GetHighResolutionTime

DEF MAX_BYTES_PER_FRAME = 1024
DEF MAX_INPUT_FRAMES = 5
DEF MAX_FRAME_LENGTH=        480
DEF FRAME_LENGTH_MS =        20
DEF MAX_API_FS_KHZ  =        48
DEF MAX_LBRR_DELAY  =        2
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
        unsigned char *p1
        unsigned char *p2

    for i in range(len):
        tmp = vec[i]
        p1 = <unsigned char *> &vec[i]
        p2 = <unsigned char *> &tmp
        p1[0] = p2[1]
        p1[1] = p2[0]


class TransCodeException(Exception):
    pass


cdef class Transcoder:
    def __init__(self):
        pass

    @cdivision(True)
    cpdef int encode_file(self,
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
            FILE*bitOutFile
            FILE*speechInFile
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
            raise TransCodeException(f"SKP_Silk_create_encoder returned {ret}")

        psEnc = PyMem_Malloc(encSizeBytes)
        ret = api.SKP_Silk_SDK_InitEncoder(psEnc, &encStatus)
        if ret:
            raise TransCodeException(f"SKP_Silk_reset_encoder returned {ret}")

        encControl.API_sampleRate = API_fs_Hz
        encControl.maxInternalSampleRate = max_internal_fs_Hz
        encControl.packetSize = (packetSize_ms * API_fs_Hz) / 1000
        encControl.packetLossPercentage = packetLoss_perc
        encControl.useInBandFEC = INBandFEC_enabled
        encControl.useDTX = DTX_enabled
        encControl.complexity = complexity_mode
        encControl.bitRate = targetRate_bps

        if API_fs_Hz > max_api_fs_khz * 1000 or API_fs_Hz < 0:
            raise TransCodeException(f"API sampling rate = {API_fs_Hz} out of range, valid range 8000 - 48000")

        while True:
            counter = fread(in_, 2, (frameSizeReadFromFile_ms * API_fs_Hz) / 1000, speechInFile)
            if byteorder:
                swap_endian(in_, counter)
            if <int> counter < ((frameSizeReadFromFile_ms * API_fs_Hz) / 1000):
                break
            nBytes = max_bytes_per_frame * max_input_frames

            ret = api.SKP_Silk_SDK_Encode(psEnc, &encControl, in_, <short> counter, payload, &nBytes)
            if ret:
                raise TransCodeException(f"SKP_Silk_Encode returned {ret}")
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
    cpdef decode_file(self, str input_file_name,
                      str output_file_name,
                      int API_Fs_Hz,
                      float loss_prob,
                      bint quiet=0):
        input_file_name_byte = input_file_name.encode("utf-8")
        output_file_name_byte = output_file_name.encode("utf-8")
        cdef:
            char*bitInFileName = input_file_name_byte
            char*speechOutFileName = output_file_name_byte
            FILE*bitInFile
            FILE*speechOutFile
            char header_buf[50]
            size_t counter
            unsigned long tottime, starttime
            double filetime
            int totPackets, i, k
            short ret, len, tot_len, nBytes
            unsigned char payload[MAX_BYTES_PER_FRAME * MAX_INPUT_FRAMES * (MAX_LBRR_DELAY + 1)]
            unsigned char*payloadEnd = NULL
            unsigned char*payloadToDec = NULL
            unsigned char FECpayload[MAX_BYTES_PER_FRAME * MAX_INPUT_FRAMES]
            unsigned char*payloadPtr
            short out[((FRAME_LENGTH_MS * MAX_API_FS_KHZ) << 1) * MAX_INPUT_FRAMES]
            short *outPtr
            short nBytesFEC
            short nBytesPerPacket[MAX_LBRR_DELAY + 1]
            short totBytes
            int decSizeBytes, packetSize_ms, frames, lost
            void*psDec
            SKP_SILK_SDK_DecControlStruct DecControl
            unsigned char Tencent_break = 0x02
        bitInFile = fopen(bitInFileName, "rb");
        if bitInFile is NULL:
            raise FileNotFoundError(f"Error: could not open input file {bitInFileName}")

        # Check Silk header
        fread(header_buf, sizeof(char), 1, bitInFile);
        header_buf[1] = <unsigned char> 0  # * Terminate with a null character
        if strcmp(header_buf, <char*> &Tencent_break):
            counter = fread(header_buf, sizeof(char), strlen("!SILK_V3"), bitInFile)
            header_buf[strlen("!SILK_V3")] = <unsigned char> 0  # * Terminate with a null character
            if strcmp(header_buf, "!SILK_V3") != 0:
                # Non-equal strings
                raise TransCodeException(f"Error: Wrong Header {header_buf}")
        else:
            counter = fread(header_buf, sizeof(char), strlen("#!SILK_V3"), bitInFile)
            header_buf[strlen("#!SILK_V3")] = <unsigned char> 0  # Terminate with a null character
            if strcmp(header_buf, "#!SILK_V3") != 0:
                # Non-equal strings
                raise TransCodeException(f"Error: Wrong Header {header_buf}")

        speechOutFile = fopen(speechOutFileName, "wb")
        if speechOutFile is NULL:
            raise TransCodeException(f"Error: could not open output file {speechOutFileName}")
        # Set the samplingrate that is requested for the output
        if API_Fs_Hz == 0:
            DecControl.API_sampleRate = 24000
        else:
            DecControl.API_sampleRate = API_Fs_Hz
        # Initialize to one frame per packet, for proper concealment before first packet arrives
        DecControl.framesPerPacket = 1
        # Create decoder
        ret = api.SKP_Silk_SDK_Get_Decoder_Size(&decSizeBytes)
        # if ret:
        #     print("SKP_Silk_SDK_Get_Decoder_Size returned %d", ret)
        psDec = PyMem_Malloc(decSizeBytes)  # todo free
        # Reset decoder
        ret = api.SKP_Silk_SDK_InitDecoder(psDec)
        # if ret:
        #     print("\nSKP_Silk_InitDecoder returned %d", ret);
        totPackets = 0
        tottime = 0
        payloadEnd = payload
        # Simulate the jitter buffer holding MAX_FEC_DELAY packets
        for i in range(MAX_LBRR_DELAY):
            # Read payload size
            counter = fread(&nBytes, sizeof(short), 1, bitInFile)
            # Read payload
            counter = fread(payloadEnd, sizeof(unsigned char), nBytes, bitInFile)
            if <short> counter < nBytes:
                break
            nBytesPerPacket[i] = nBytes
            payloadEnd += nBytes
            totPackets += 1

        while True:
            # Read payload size */
            counter = fread(&nBytes, sizeof(short), 1, bitInFile)
            if nBytes < 0 or counter < 1:
                break
            # Read payload */
            counter = fread(payloadEnd, sizeof(unsigned char), nBytes, bitInFile)
            if <short> counter < nBytes:
                break
            # Simulate losses */
            rand_seed = <int> (<unsigned int> 907633515 + <unsigned int> (<unsigned int> 1 * <unsigned int> 196314165))
            if ((<float> ((rand_seed >> 16) + (1 << 15))) / 65535.0 >= (loss_prob / 100.0)) and (counter > 0):
                nBytesPerPacket[MAX_LBRR_DELAY] = nBytes
                payloadEnd += nBytes
            else:
                nBytesPerPacket[MAX_LBRR_DELAY] = 0
            if nBytesPerPacket[0] == 0:
                # Indicate lost packet */
                lost = 1
                # Packet loss. Search after FEC in next packets. Should be done in the jitter buffer */
                payloadPtr = payload
                for i in range(MAX_LBRR_DELAY):
                    if nBytesPerPacket[i + 1] > 0:
                        starttime = GetHighResolutionTime()
                        api.SKP_Silk_SDK_search_for_LBRR(payloadPtr, nBytesPerPacket[i + 1], (i + 1), FECpayload,
                                                         &nBytesFEC)
                        tottime += GetHighResolutionTime() - starttime
                        if nBytesFEC > 0:
                            payloadToDec = FECpayload
                            nBytes = nBytesFEC
                            lost = 0
                            break
                    payloadPtr += nBytesPerPacket[i + 1]
            else:
                lost = 0
                nBytes = nBytesPerPacket[0]
                payloadToDec = payload

            # Silk decoder */
            outPtr = out
            tot_len = 0
            starttime = GetHighResolutionTime()
            if lost == 0:
                # No Loss: Decode all frames in the packet */
                frames = 0
                ret = api.SKP_Silk_SDK_Decode(psDec, &DecControl, 0, payloadToDec, nBytes, outPtr, &len)
                # if ret:
                #     printf("\nSKP_Silk_SDK_Decode returned %d", ret);

                frames += 1
                outPtr += len
                tot_len += len
                if frames > MAX_INPUT_FRAMES:
                    # Hack for corrupt stream that could generate too many frames */
                    outPtr = out
                    tot_len = 0
                    frames = 0
                while DecControl.moreInternalDecoderFrames:
                    # Decode 20 ms */
                    ret = api.SKP_Silk_SDK_Decode(psDec, &DecControl, 0, payloadToDec, nBytes, outPtr, &len)
                    # if ret:
                    #     printf("\nSKP_Silk_SDK_Decode returned %d", ret);

                    frames += 1
                    outPtr += len
                    tot_len += len
                    if frames > MAX_INPUT_FRAMES:
                        # Hack for corrupt stream that could generate too many frames */
                        outPtr = out
                        tot_len = 0
                        frames = 0

                    # Until last 20 ms frame of packet has been decoded */
            else:
                # Loss: Decode enough frames to cover one packet duration */
                for i in range(DecControl.framesPerPacket):
                    # Generate 20 ms */
                    ret = api.SKP_Silk_SDK_Decode(psDec, &DecControl, 1, payloadToDec, nBytes, outPtr, &len)
                    # if ret:
                    #     print("\nSKP_Silk_Decode returned %d", ret)
                    outPtr += len
                    tot_len += len

            packetSize_ms = <int>(tot_len / (DecControl.API_sampleRate / 1000))
            tottime += GetHighResolutionTime() - starttime
            totPackets += 1

            # Write output to file */
            fwrite(out, sizeof(short), tot_len, speechOutFile)
            # Update buffer */
            totBytes = 0;
            for i in range(MAX_LBRR_DELAY):
                totBytes += nBytesPerPacket[i + 1]
            # Check if the received totBytes is valid */
            if totBytes < 0 or totBytes > sizeof(payload):
                raise TransCodeException(f"Packets decoded:             {totPackets}")
            memmove((payload), (&payload[nBytesPerPacket[0]]), (totBytes * sizeof(unsigned char)))
            payloadEnd -= nBytesPerPacket[0]
            memmove((nBytesPerPacket), (&nBytesPerPacket[1]), (2 * sizeof(short)))
            # if not quiet:
            #     fprintf(stderr, "\rPackets decoded:             %d", totPackets)

        # Empty the recieve buffer */
        for k in range(MAX_LBRR_DELAY):
            if nBytesPerPacket[0] == 0:
                # Indicate lost packet */
                lost = 1
                # Packet loss. Search after FEC in next packets. Should be done in the jitter buffer */
                payloadPtr = payload
                for i in range(MAX_LBRR_DELAY):
                    if nBytesPerPacket[i + 1] > 0:
                        starttime = GetHighResolutionTime()
                        api.SKP_Silk_SDK_search_for_LBRR(payloadPtr, nBytesPerPacket[i + 1], (i + 1), FECpayload,
                                                         &nBytesFEC)
                        tottime += GetHighResolutionTime() - starttime
                        if nBytesFEC > 0:
                            payloadToDec = FECpayload
                            nBytes = nBytesFEC
                            lost = 0
                            break
                    payloadPtr += nBytesPerPacket[i + 1]
            else:
                lost = 0
                nBytes = nBytesPerPacket[0]
                payloadToDec = payload
            # Silk decoder */
            outPtr = out
            tot_len = 0
            starttime = GetHighResolutionTime()

            if lost == 0:
                # No loss: Decode all frames in the packet */
                frames = 0
                ret = api.SKP_Silk_SDK_Decode(psDec, &DecControl, 0, payloadToDec, nBytes, outPtr, &len);
                # if ret:
                #     printf("\nSKP_Silk_SDK_Decode returned %d", ret);
                frames += 1
                outPtr += len
                tot_len += len
                if frames > MAX_INPUT_FRAMES:
                    # Hack for corrupt stream that could generate too many frames */
                    outPtr = out
                    tot_len = 0
                    frames = 0
                while DecControl.moreInternalDecoderFrames:
                    # Decode 20 ms */
                    ret = api.SKP_Silk_SDK_Decode(psDec, &DecControl, 0, payloadToDec, nBytes, outPtr, &len);
                    # if ret:
                    #     printf("\nSKP_Silk_SDK_Decode returned %d", ret);
                    frames += 1
                    outPtr += len
                    tot_len += len
                    if frames > MAX_INPUT_FRAMES:
                        # Hack for corrupt stream that could generate too many frames */
                        outPtr = out
                        tot_len = 0
                        frames = 0
                    # Until last 20 ms frame of packet has been decoded */
            else:
                # Loss: Decode enough frames to cover one packet duration */

                # Generate 20 ms */
                for i in range(DecControl.framesPerPacket):
                    ret = api.SKP_Silk_SDK_Decode(psDec, &DecControl, 1, payloadToDec, nBytes, outPtr, &len)
                    # if ret:
                    #     print("\nSKP_Silk_Decode returned %d", ret);
                    outPtr += len
                    tot_len += len

            packetSize_ms = <int>(tot_len / (DecControl.API_sampleRate / 1000))
            tottime += GetHighResolutionTime() - starttime
            totPackets += 1
            # Write output to file */
            fwrite(out, sizeof(short), tot_len, speechOutFile)

            # Update Buffer */
            totBytes = 0;
            for i in range(MAX_LBRR_DELAY):
                totBytes += nBytesPerPacket[i + 1]

            # Check if the received totBytes is valid */
            if totBytes < 0 or totBytes > sizeof(payload):
                raise TransCodeException(f"Packets decoded:              {totPackets}")
            memmove((payload), (&payload[nBytesPerPacket[0]]), (totBytes * sizeof(unsigned char)))
            payloadEnd -= nBytesPerPacket[0]
            memmove((nBytesPerPacket), (&nBytesPerPacket[1]), (2 * sizeof(short)))
            # if not quiet:
            #     print(stderr, "\rPackets decoded:              %d", totPackets)

        # Free decoder */
        PyMem_Free(psDec)

        # Close files */
        fclose(speechOutFile)
        fclose(bitInFile)

        filetime = totPackets * 1e-3 * packetSize_ms
        return totPackets
