//
// Created by synodriver on 2021/2/13.
//

#ifndef SILK_BYTESBUFFER_H
#define SILK_BYTESBUFFER_H
#define REALLOC_SIZE 100

#include<stdio.h>
#include<stdlib.h>
#include<string.h>

typedef enum BufferException
{
    Ok = (unsigned char) 0, // 0
    MemoryException, // 1 没内存了
    BufferError // 2 越界了
} BufferException;

typedef struct Bytebuffer
{
    unsigned char* data; // 数据
    size_t len; // 实际数据长度
    size_t position; // 当前读取位置指针
    size_t malloced; // 申请的内存大小
} Bytebuffer;

// 初始化结构体
Bytebuffer* Bytebuffer_New(size_t malloced,    // 申请初始内存大小
                           unsigned char* flag);  // 成功标志

void Bytebuffer_Del(Bytebuffer** self); // 析构函数
//赋值
void Bytebuffer_Init(Bytebuffer* self,
                     unsigned char* data, // 初始化数据化
                     size_t len, // 塞进去的字节数
                     unsigned char* flag);  // 成功标志

// 读取一个字节，指针++
unsigned char Bytebuffer_Read(Bytebuffer* self,
                              unsigned char* flag);

// 读取size个字节   返回自己的数据指针 深拷贝 指针++
unsigned char* Bytebuffer_ReadBytes(Bytebuffer* self,
                                    size_t size, // 读取字节数
                                    unsigned char* flag);

// 读取一个short 指针+=2
short Bytebuffer_ReadShort(Bytebuffer* self,
                           unsigned char* flag);

// 读取一个ushort 指针+=2
unsigned short Bytebuffer_ReadUShort(Bytebuffer* self,
                                     unsigned char* flag);

int Bytebuffer_ReadInt(Bytebuffer* self,
                       unsigned char* flag);

unsigned int Bytebuffer_ReadUInt(Bytebuffer* self,
                                 unsigned char* flag);

long long Bytebuffer_ReadInt64(Bytebuffer* self,
                               unsigned char* flag);

unsigned long long Bytebuffer_ReadUInt64(Bytebuffer* self,
                                         unsigned char* flag);

float Bytebuffer_ReadFloat(Bytebuffer* self,
                           unsigned char* flag);

double Bytebuffer_ReadDouble(Bytebuffer* self,
                             unsigned char* flag);

void Bytebuffer_WriteByte(Bytebuffer* self,
                          unsigned char c,  // 要写入的那个字节
                          unsigned char* flag);

void Bytebuffer_WriteBytes(Bytebuffer* self,
                           unsigned char* c,  // 要写入的那个字节
                           size_t len, // 长度
                           unsigned char* flag);

void Bytebuffer_WriteShort(Bytebuffer* self,
                           short c,  // 要写入的那个数字
                           unsigned char* flag);

void Bytebuffer_WriteUShort(Bytebuffer* self,
                            unsigned short c,  // 要写入的那个数字
                            unsigned char* flag);

void Bytebuffer_WriteInt(Bytebuffer* self,
                         int c,  // 要写入的那个数字
                         unsigned char* flag);

void Bytebuffer_WriteUInt(Bytebuffer* self,
                          unsigned int c,  // 要写入的那个数字
                          unsigned char* flag);

void Bytebuffer_WriteInt64(Bytebuffer* self,
                           long long c,  // 要写入的那个数字
                           unsigned char* flag);

void Bytebuffer_WriteUInt64(Bytebuffer* self,
                            unsigned long long c,  // 要写入的那个数字
                            unsigned char* flag);

void Bytebuffer_WriteFloat(Bytebuffer* self,
                           float c,  // 要写入的那个数字
                           unsigned char* flag);

void Bytebuffer_WriteDouble(Bytebuffer* self,
                            double c,  // 要写入的那个数字
                            unsigned char* flag);

Bytebuffer* Bytebuffer_Copy(Bytebuffer* self,
                            unsigned char* flag); // 深拷贝


void Bytebuffer_Seek(Bytebuffer* self,
                     size_t position,  // 定位读取指针
                     unsigned char* flag);


#endif //SILK_BYTESBUFFER_H
