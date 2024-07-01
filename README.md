# MTRISC

一个简单的32位冯诺伊曼架构的CPU， 指令比较简单， 简单到可以手动汇编，代码结构易懂，而且是冯诺依曼架构的（大部分自己实现的都是哈佛架构的）

## 指令结构
指令全部是32位的， 如下所示， op是操作码， 如加减乘除 ， r1是第一个寄存器的索引， r2是第二个寄存器的索引， 剩下的16位是立即数

    // instru format : 32bit
    // 0x-xx----xx---xx---xxxx
    //    |      |    |     |
    //   op    r1     r2   data
    
## 寄存器结构
这里我定义了大量空闲的寄存器，如果看其他的指令集， 如ARM和MIPS， 通常指令是有三个寄存器索引的， 这里我偷懒，把输出的寄存器永远定义成了rd，即第四个寄存器， 如执行add rb, ra 命令， 那么， 其实rb + ra的结果是在rd寄存器里面的。


    // reg index
    // zo : 0	always 0
    // ra : 1	alu parameter 1
    // rb : 2	alu parameter 2
    // rc : 3	alu parameter 3
    // rd : 4	alu output 1
    // re : 5	alu output 2
    // rf : 6	temp 1
    // rg : 7	temp 2
    // rh ：8    temp 3
    // ri : 9    temp 4
    // rj : 10   temp 5
    // rk : 11   temp 6
    // rl : 12   temp 7
    // rm : 13   temp 8
    // rn : 14   temp 9
    // ro : 15   temp 10
    // mo : 16   mode and status
    // the op is as blow
    
## 指令集
支持的指令如下：

支持硬件的乘法和除法， 厉害吧， 不是我NB，是FPGA牛逼， 现在也别想着手写乘法器了， FPGA厂商和晶圆代工厂都有成熟的乘除法器，直接拿来用就行了， 你见过有人用晶体管自己搭NE555吗

    parameter NOP = 8'hff;     // nop
    parameter HALT = 8'h00;    // halt
    parameter LDH = 8'h01;     // ldh rn, xxxx
    parameter LDL = 8'h02;     // ldl rn, xxxx
    parameter MOV = 8'h05;     // mov rn, rm
    
    
    parameter CLR = 8'h13;     // clr rn
    parameter INC = 8'h14;    // inc rn
    parameter DEC = 8'h15;    // dec rn
    parameter ADD = 8'h16;     // add rn, rm
    parameter SUB = 8'h17;    // dec rn, rm
    parameter MUL = 8'h18;    // mul rn, rm
    parameter DIV = 8'h19;    // div rn, rm
    parameter LSF = 8'h1a;    // lsf rn, rm
    parameter RSF = 8'h1b;    // rsf rn, rm
    
    parameter AND = 8'h20;    // and rn, rm
    parameter OR  = 8'h21;    // or rn, rm
    parameter XOR = 8'h22;    // xor rn, rm
    parameter NOT = 8'h23;   // not rn
    
    parameter STACK = 8'h40;   // stack rn
    parameter POP  = 8'h62;   // pop rm
    
    parameter PUSH  = 8'h51;  // push rn
    parameter STR = 8'h53;     // str rn, [rm]
    parameter STD = 8'h54;     // std rn, [0000]
    
    parameter IFEQ = 8'h33;   // ifeq rn, rm
    parameter IFNQ = 8'h34;   // ifnq rn, rm
    parameter IFLG = 8'h35;   // iflg rn, rm
    parameter IFSM = 8'h36;   // ifsm rn, rm
    parameter JPR  = 8'h37;   // jpr rn
    parameter JPD  = 8'h38;   // jpd xxxx
    
    parameter LDR = 8'h63;     // ldr rn, [rm


我们的指令主要分成几类， 一类是寄存器存取指令， 如LDH 、LDL、MOV这些， 一类是算数指令， 如ADD、DEC、MUL、DIV这些， 一类是跳转指令， 即ifeq、 ifnq， jpr（跳到寄存器的地址）， jpd等等。还有以内是内存操作指令， 如LDR、STR、STD， 这些指令都非常消耗时间。

从上面的指令和寄存器来看， 我们的指令集定义得非常的简单易懂， 甚至可以用手直接写代码

比如想把mul rb, ra 这条指令翻译成机器码， 那我们只要查上面的定义：
1. mul是0x18
2. rb是2
3. ra是1
4. 立即数全是空的， 也就是0000

那么把上面的数字拼起来， 这个指令就是0x18210000， 非常简单吧
## 内部状态

目前CPU的状态是：取指令、运行指令、取内存数据、写内存数据、等待、 错误，这几个， 当前是只有一个状态运行， 后续可以改成流水线

    parameter INIT = 0;
    parameter FETCH = 1;
    parameter EXEC = 2;
    parameter LOAD = 3;
    parameter STORE = 4;
    parameter IDLE = 5;
    parameter ERROR = 6;

## 汇编代码

在FPGA中初始化了一个ram， 初始化的内容就是运行的代码，这段程序对CPU的加减乘除进行了测试， 结果存入00f0地址，再取出来到rd，在跳到0000首地址，注意我这里设计的CPU是冯诺依曼架构的， 也就是说内存既装指令也装数据，目前看到大部分的自己设计的CPU都是哈佛架构的

    DEPTH = 256;
    WIDTH = 32;
    ADDRESS _RADIX = HEX;
    DATA_RADIX = HEX;
    -- Specify initial data values for memory, format is address : data
    CONTENT BEGIN
    [00..FF]    :   00000000;
    -- Initialize from course website data
    00  :    ff000000;     --nop
    04  :    ff000000;     --nop
    08  :    02100005;    --ldl ra, 0005  //ra = 0005
    0C  :    02200001;   --ldl rb,  0001   
    10  :    01201000;   --ldh, rb, 1000  //rd = 1000 0001
    14  :    16210000;   --add rb, ra      //rd = 1000 0006
    18  :    17210000;   --sub rb, ra      // rd = 0fff fffc
    1C  :    18210000;   --mul rb, ra     // rd = 5000 0005
    20  :    19210000;   -- div rb, ra   // rd = 0333 3333
    24  :    13100000;    --clr ra
    28  :    02100000;    --ldl ra 0000
    2C  :    544000f0;    --sta rd ,00f0
    30  :    13400000;    --clr  rd
    34  :    13400000;    -- clr  rd
    38  :    634000f0;    -- ldr rd ，00f0
    3C  :    38000000;
    END;

## 验证结果

使用DE2进行验证， 视频如下：
