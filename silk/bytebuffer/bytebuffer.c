//
// Created by synodriver on 2021/2/13.
//

#include "bytebuffer.h"

// 初始化结构体
Bytebuffer* Bytebuffer_New(size_t malloced,    // 申请初始内存大小
                           unsigned char* flag)  // 成功标志
{
    Bytebuffer* self = (Bytebuffer*) malloc(sizeof(Bytebuffer));
    self->data = (unsigned char*) malloc(malloced);
    if (self->data == NULL)
    {
        *flag = MemoryException;
        return NULL;
    }
    self->len = 0;
    self->position = 0;
    self->malloced = malloced;
    return self;
}

void Bytebuffer_Del(Bytebuffer** self)
{
    free((*self)->data);
    (*self)->data = NULL;
    free(*self);
    *self = NULL;
}

void Bytebuffer_Init(Bytebuffer* self,
                     unsigned char* data, // 初始化数据化
                     size_t len, // 塞进去的字节数
                     unsigned char* flag)  // 成功标志
{
    if (len > self->malloced) // 比自己内存大 装不下
    {
        self->data = (unsigned char*) realloc(self->data, len + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = len;
    }
    memcpy(self->data, data, len);
    self->len = len;
    *flag = Ok;
}

// 读取一个字节，指针++
unsigned char Bytebuffer_Read(Bytebuffer* self,
                              unsigned char* flag)
{
    if ((self->position + sizeof(unsigned char)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }
    unsigned char c = self->data[self->position];
    self->position++;
    *flag = Ok;
    return c;
}

// 读取size个字节   返回自己的数据指针  深拷贝 指针++
unsigned char* Bytebuffer_ReadBytes(Bytebuffer* self,
                                    size_t size, // 读取字节数
                                    unsigned char* flag)
{
    unsigned char* data = (unsigned char*) malloc(size);
    if (data == NULL) // 内存不足
    {
        *flag = MemoryException;
        return NULL;
    }
    if ((self->position + size) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }

    memcpy(data, self->data + self->position, size);
    *flag = Ok;
    self->position += size;
    return data
}

// 读取一个short 指针++
short Bytebuffer_ReadShort(Bytebuffer* self,
                           unsigned char* flag)
{
    if ((self->position + sizeof(short)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }

    short data = *(short*) (self->data + self->position);

    self->position += sizeof(short);
    *flag = Ok;
    return data;
}

unsigned short Bytebuffer_ReadUShort(Bytebuffer* self,
                                     unsigned char* flag)
{
    if ((self->position + sizeof(unsigned short)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }

    unsigned short data = *(unsigned short*) (self->data + self->position);
    self->position += sizeof(unsigned short);
    *flag = Ok;
    return data;

}

int Bytebuffer_ReadInt(Bytebuffer* self,
                       unsigned char* flag)
{
    if ((self->position + sizeof(int)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }

    int data = *(int*) (self->data + self->position);
    self->position += sizeof(int);
    *flag = Ok;
    return data;
}

unsigned int Bytebuffer_ReadUInt(Bytebuffer* self,
                                 unsigned char* flag)
{
    if ((self->position + sizeof(unsigned int)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }
    unsigned int data = *(unsigned int*) (self->data + self->position);
    self->position += sizeof(unsigned int);
    *flag = Ok;
    return data;
}

long long Bytebuffer_ReadInt64(Bytebuffer* self,
                               unsigned char* flag)
{
    if ((self->position + sizeof(long long)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }
    long long data = *(long long*) (self->data + self->position);
    self->position += sizeof(long long);
    *flag = Ok;
    return data;
}


unsigned long long Bytebuffer_ReadUInt64(Bytebuffer* self,
                                         unsigned char* flag)
{
    if ((self->position + sizeof(unsigned long long)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }
    unsigned long long data = *(unsigned long long*) (self->data + self->position);
    self->position += sizeof(unsigned long long);
    *flag = Ok;
    return data;
}

float Bytebuffer_ReadFloat(Bytebuffer* self,
                           unsigned char* flag)
{
    if ((self->position + sizeof(float)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }
    float data = *(float*) (self->data + self->position);
    self->position += sizeof(float);
    *flag = Ok;
    return data;
}

double Bytebuffer_ReadDouble(Bytebuffer* self,
                             unsigned char* flag)
{

    if ((self->position + sizeof(double)) > (self->len))   // 长度超过
    {
        *flag = BufferError;
        return NULL;
    }
    double data = *(double*) (self->data + self->position);
    self->position += sizeof(double);
    *flag = Ok;
    return data;
}

void Bytebuffer_WriteByte(Bytebuffer* self,
                          unsigned char c,  // 要写入的那个字节
                          unsigned char* flag)
{
    if (self->len + sizeof(char) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->malloced + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced += REALLOC_SIZE;

    }
    *flag = Ok;
    self->data[self->position] = c
    self->position += sizeof(char);
    self->len += sizeof(char);
}

void Bytebuffer_WriteBytes(Bytebuffer* self,
                           unsigned char* c,  // 要写入的那个字节
                           size_t len, // 长度
                           unsigned char* flag)
{
    if (self->len + len > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + len + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + len + REALLOC_SIZE;

    }
    *flag = Ok;
    memcpy(self->data + self->position, c, len);
    self->position += len;
    self->len += len;
}

void Bytebuffer_WriteShort(Bytebuffer* self,
                           short c,  // 要写入的那个数字
                           unsigned char* flag)
{
    if (self->len + sizeof(short) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(short) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(short) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(short*) (self->data + self->position) = c;
    self->position += sizeof(short);
    self->len += sizeof(short);
}

void Bytebuffer_WriteUShort(Bytebuffer* self,
                            unsigned short c,  // 要写入的那个数字
                            unsigned char* flag)
{
    if (self->len + sizeof(unsigned short) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(unsigned short) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(unsigned short) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(unsigned short*) (self->data + self->position) = c;
    self->position += sizeof(unsigned short);
    self->len += sizeof(unsigned short);
}

void Bytebuffer_WriteInt(Bytebuffer* self,
                         int c,  // 要写入的那个数字
                         unsigned char* flag)
{
    if (self->len + sizeof(int) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(int) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(int) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(int*) (self->data + self->position) = c;
    self->position += sizeof(int);
    self->len += sizeof(int);
}

void Bytebuffer_WriteUInt(Bytebuffer* self,
                          unsigned int c,  // 要写入的那个数字
                          unsigned char* flag)
{
    if (self->len + sizeof(unsigned int) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(unsigned int) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(unsigned int) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(unsigned int*) (self->data + self->position) = c;
    self->position += sizeof(unsigned int);
    self->len += sizeof(unsigned int);
}

void Bytebuffer_WriteInt64(Bytebuffer* self,
                           long long c,  // 要写入的那个数字
                           unsigned char* flag)
{
    if (self->len + sizeof(long long) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(long long) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(long long) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(long long*) (self->data + self->position) = c;
    self->position += sizeof(long long);
    self->len += sizeof(long long);
}

void Bytebuffer_WriteUInt64(Bytebuffer* self,
                            unsigned long long c,  // 要写入的那个数字
                            unsigned char* flag)
{
    if (self->len + sizeof(unsigned long long) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(unsigned long long) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(unsigned long long) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(unsigned long long*) (self->data + self->position) = c;
    self->position += sizeof(unsigned long long);
    self->len += sizeof(unsigned long long);
}

void Bytebuffer_WriteFloat(Bytebuffer* self,
                           float c,  // 要写入的那个数字
                           unsigned char* flag)
{
    if (self->len + sizeof(float) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(float) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(float) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(float*) (self->data + self->position) = c;
    self->position += sizeof(float);
    self->len += sizeof(float);
}

void Bytebuffer_WriteDouble(Bytebuffer* self,
                            double c,  // 要写入的那个数字
                            unsigned char* flag)
{
    if (self->len + sizeof(double) > self->malloced) // 要realloc
    {
        self->data = (unsigned char*) realloc(self->data, self->len + sizeof(double) + REALLOC_SIZE);
        if (self->data == NULL)
        {
            *flag = MemoryException;
            return;
        }
        self->malloced = self->len + sizeof(double) + REALLOC_SIZE;
    }
    *flag = Ok;
    *(double*) (self->data + self->position) = c;
    self->position += sizeof(double);
    self->len += sizeof(double);
}

Bytebuffer* Bytebuffer_Copy(Bytebuffer* self,
                            unsigned char* flag)
{
    unsigned char flag;
    Bytebuffer* new = Bytebuffer_New(self->malloced, &flag);
    if (new == NULL)
    {
        *flag = MemoryException;
        return NULL;
    }
    new->position = self->position;
    new->len = self->len;
    memcpy(new->data, self->data, self->len);
    *flag = Ok;
    return new;
}

void Bytebuffer_Seek(Bytebuffer* self,
                     size_t position,  // 定位读取指针
                     unsigned char* flag)
{
    if (position < 0 || position > self->len)
    {
        *flag = BufferError;
        return;
    }
    *flag = Ok;
    self->position = position
}