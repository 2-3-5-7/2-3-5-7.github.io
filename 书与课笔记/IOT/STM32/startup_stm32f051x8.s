;******************** (C) COPYRIGHT 2016 STMicroelectronics ********************
;* File Name          : startup_stm32f051x8.s
;* Author             : MCD Application Team
;* Description        : STM32F051x4/STM32F051x6/STM32F051x8 devices vector table for MDK-ARM toolchain.
;*                      This module performs:
;*                      - Set the initial SP
;*                      - Set the initial PC == Reset_Handler
;*                      - Set the vector table entries with the exceptions ISR address
;*                      - Branches to __main in the C library (which eventually
;*                        calls main()).
;*                      After Reset the CortexM0 processor is in Thread mode,
;*                      priority is Privileged, and the Stack is set to Main.
;* <<< Use Configuration Wizard in Context Menu >>>
;*******************************************************************************
;*
;* Redistribution and use in source and binary forms, with or without modification,
;* are permitted provided that the following conditions are met:
;*   1. Redistributions of source code must retain the above copyright notice,
;*      this list of conditions and the following disclaimer.
;*   2. Redistributions in binary form must reproduce the above copyright notice,
;*      this list of conditions and the following disclaimer in the documentation
;*      and/or other materials provided with the distribution.
;*   3. Neither the name of STMicroelectronics nor the names of its contributors
;*      may be used to endorse or promote products derived from this software
;*      without specific prior written permission.
;*
;* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
;* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;*******************************************************************************

; Amount of memory (in bytes) allocated for Stack
; Tailor this value to your application needs
; <h> Stack Configuration
;   <o> Stack Size (in Bytes) <0x0-0xFFFFFFFF:8>
; </h>

Stack_Size	 EQU     0x400									;定义栈的大小1K

                AREA    STACK, NOINIT, READWRITE, ALIGN=3	;AREA 是定义一个段，此处定义的是栈段，没有初始化的段，可读可写，align是说段的起始地址应该是8的倍数
Stack_Mem       SPACE   Stack_Size							;SPACE 是为栈分配空间，开辟栈空间大小为0x400
__initial_sp												;__initial_sp是个标号，这个标号指向栈的栈顶


; <h> Heap Configuration
;   <o>  Heap Size (in Bytes) <0x0-0xFFFFFFFF:8>
; </h>

Heap_Size      EQU     0x200								;定义堆的大小 512B

                AREA    HEAP, NOINIT, READWRITE, ALIGN=3
__heap_base													;堆的起始地址
Heap_Mem        SPACE   Heap_Size							;堆的大小
__heap_limit												;堆的结束地址

                PRESERVE8
                THUMB


; Vector Table Mapped to Address 0 at Reset
                AREA    RESET, DATA, READONLY		;此处定义的数据段，数据段放的是中断向量表，只读
                EXPORT  __Vectors					;EXPORT在程序中声明一个全局的标号__Vectors，该标号可在其它的文件中引用
                EXPORT  __Vectors_End
                EXPORT  __Vectors_Size
											;DCD指令以字为单位分配内存，要求4字节对齐，并要求初始化这些内存。
											;在向量表中，DCD 分配了一堆内存，并且以 ESR 的入口地址初始化它们。
												
												
__Vectors       DCD     __initial_sp                   ; Top of Stack    存放__initial_sp，也就是堆栈栈顶的地址
                DCD     Reset_Handler                  ; Reset Handler
                DCD     NMI_Handler                    ; NMI Handler
                DCD     HardFault_Handler              ; Hard Fault Handler
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     SVC_Handler                    ; SVCall Handler
                DCD     0                              ; Reserved
                DCD     0                              ; Reserved
                DCD     PendSV_Handler                 ; PendSV Handler
                DCD     SysTick_Handler                ; SysTick Handler

                ; External Interrupts
                DCD     WWDG_IRQHandler                ; Window Watchdog
                DCD     PVD_IRQHandler                 ; PVD through EXTI Line detect
                DCD     RTC_IRQHandler                 ; RTC through EXTI Line
                DCD     FLASH_IRQHandler               ; FLASH
                DCD     RCC_IRQHandler                 ; RCC
                DCD     EXTI0_1_IRQHandler             ; EXTI Line 0 and 1
                DCD     EXTI2_3_IRQHandler             ; EXTI Line 2 and 3
                DCD     EXTI4_15_IRQHandler            ; EXTI Line 4 to 15
                DCD     TSC_IRQHandler                 ; TS
                DCD     DMA1_Channel1_IRQHandler       ; DMA1 Channel 1
                DCD     DMA1_Channel2_3_IRQHandler     ; DMA1 Channel 2 and Channel 3
                DCD     DMA1_Channel4_5_IRQHandler     ; DMA1 Channel 4 and Channel 5
                DCD     ADC1_COMP_IRQHandler           ; ADC1, COMP1 and COMP2 
                DCD     TIM1_BRK_UP_TRG_COM_IRQHandler ; TIM1 Break, Update, Trigger and Commutation
                DCD     TIM1_CC_IRQHandler             ; TIM1 Capture Compare
                DCD     TIM2_IRQHandler                ; TIM2
                DCD     TIM3_IRQHandler                ; TIM3
                DCD     TIM6_DAC_IRQHandler            ; TIM6 and DAC
                DCD     0                              ; Reserved
                DCD     TIM14_IRQHandler               ; TIM14
                DCD     TIM15_IRQHandler               ; TIM15
                DCD     TIM16_IRQHandler               ; TIM16
                DCD     TIM17_IRQHandler               ; TIM17
                DCD     I2C1_IRQHandler                ; I2C1
                DCD     I2C2_IRQHandler                ; I2C2
                DCD     SPI1_IRQHandler                ; SPI1
                DCD     SPI2_IRQHandler                ; SPI2
                DCD     USART1_IRQHandler              ; USART1
                DCD     USART2_IRQHandler              ; USART2
                DCD     0                              ; Reserved
                DCD     CEC_IRQHandler                 ; CEC

__Vectors_End

__Vectors_Size  EQU  __Vectors_End - __Vectors

                AREA    |.text|, CODE, READONLY		 ;text  一般代表代码段

; Reset handler routine
Reset_Handler    PROC
                 EXPORT  Reset_Handler                 [WEAK]     ;“[WEAK]”是一个弱符号声明，就是告诉编译器，我这里声明的标号的优先权低于其它同名的标号，也就是说如果在工程中还有别的函数和我同名，那么你就调用和我同名的其它函数，如果没有同名的，那你就调用我。
        IMPORT  __main									 ;IMPORT则表明后面标号所代表的函数是调用其它文件的
        IMPORT  SystemInit  
                 LDR     R0, =SystemInit			;复位子程序是系统上电后第一个执行的程序，调用 SystemInit 函数初始化系统时钟
                 BLX     R0
                 LDR     R0, =__main                   ;__main 是一个标准的 C 库函数，主要作用是初始化用户堆栈，并在函数的最后调用main 函数去到 C 的世界
                 BX      R0
                 ENDP

; Dummy Exception Handlers (infinite loops which can be modified)

NMI_Handler     PROC
                EXPORT  NMI_Handler                    [WEAK]  
                B       .
                ENDP
HardFault_Handler\
                PROC
                EXPORT  HardFault_Handler              [WEAK]
                B       .
                ENDP
SVC_Handler     PROC
                EXPORT  SVC_Handler                    [WEAK]
                B       .
                ENDP
PendSV_Handler  PROC
                EXPORT  PendSV_Handler                 [WEAK]
                B       .
                ENDP
SysTick_Handler PROC
                EXPORT  SysTick_Handler                [WEAK]
                B       .
                ENDP

Default_Handler PROC

                EXPORT  WWDG_IRQHandler                [WEAK]
                EXPORT  PVD_IRQHandler                 [WEAK]
                EXPORT  RTC_IRQHandler                 [WEAK]
                EXPORT  FLASH_IRQHandler               [WEAK]
                EXPORT  RCC_IRQHandler                 [WEAK]
                EXPORT  EXTI0_1_IRQHandler             [WEAK]
                EXPORT  EXTI2_3_IRQHandler             [WEAK]
                EXPORT  EXTI4_15_IRQHandler            [WEAK]
                EXPORT  TSC_IRQHandler                 [WEAK]
                EXPORT  DMA1_Channel1_IRQHandler       [WEAK]
                EXPORT  DMA1_Channel2_3_IRQHandler     [WEAK]
                EXPORT  DMA1_Channel4_5_IRQHandler     [WEAK]
                EXPORT  ADC1_COMP_IRQHandler           [WEAK]
                EXPORT  TIM1_BRK_UP_TRG_COM_IRQHandler [WEAK]
                EXPORT  TIM1_CC_IRQHandler             [WEAK]
                EXPORT  TIM2_IRQHandler                [WEAK]
                EXPORT  TIM3_IRQHandler                [WEAK]
                EXPORT  TIM6_DAC_IRQHandler            [WEAK]
                EXPORT  TIM14_IRQHandler               [WEAK]
                EXPORT  TIM15_IRQHandler               [WEAK]
                EXPORT  TIM16_IRQHandler               [WEAK]
                EXPORT  TIM17_IRQHandler               [WEAK]
                EXPORT  I2C1_IRQHandler                [WEAK]
                EXPORT  I2C2_IRQHandler                [WEAK]
                EXPORT  SPI1_IRQHandler                [WEAK]
                EXPORT  SPI2_IRQHandler                [WEAK]
                EXPORT  USART1_IRQHandler              [WEAK]
                EXPORT  USART2_IRQHandler              [WEAK]
                EXPORT  CEC_IRQHandler                 [WEAK]


WWDG_IRQHandler
PVD_IRQHandler
RTC_IRQHandler
FLASH_IRQHandler
RCC_IRQHandler
EXTI0_1_IRQHandler
EXTI2_3_IRQHandler
EXTI4_15_IRQHandler
TSC_IRQHandler
DMA1_Channel1_IRQHandler
DMA1_Channel2_3_IRQHandler
DMA1_Channel4_5_IRQHandler
ADC1_COMP_IRQHandler
TIM1_BRK_UP_TRG_COM_IRQHandler
TIM1_CC_IRQHandler
TIM2_IRQHandler
TIM3_IRQHandler
TIM6_DAC_IRQHandler
TIM14_IRQHandler
TIM15_IRQHandler
TIM16_IRQHandler
TIM17_IRQHandler
I2C1_IRQHandler
I2C2_IRQHandler
SPI1_IRQHandler
SPI2_IRQHandler
USART1_IRQHandler
USART2_IRQHandler
CEC_IRQHandler

                B       .

                ENDP

                ALIGN

;*******************************************************************************
; User Stack and Heap initialization
;*******************************************************************************
                 IF      :DEF:__MICROLIB       ;检查是否定义了__MICROLIB,如果定义了则条件成立。用户可以在配置软件中勾选。
									  ;用户栈和堆初始化,由C库函数_main来完成
                 EXPORT  __initial_sp		  ;栈顶地址
                 EXPORT  __heap_base		  ;堆起始地址
                 EXPORT  __heap_limit          ;堆结束地址

                 ELSE					

                 IMPORT  __use_two_region_memory 	  
                 EXPORT  __user_initial_stackheap   ;用户自己来初始化堆栈

__user_initial_stackheap

                 LDR     R0, =  Heap_Mem
                 LDR     R1, = (Stack_Mem + Stack_Size)
                 LDR     R2, = (Heap_Mem +  Heap_Size)
                 LDR     R3, =  Stack_Mem
                 BX      LR

                 ALIGN

                 ENDIF

                 END

;************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE*****
