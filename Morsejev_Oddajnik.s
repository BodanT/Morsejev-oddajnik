.equ PMC_BASE,  0xFFFFFC00  /* (PMC) Base Address */
.equ CKGR_MOR,	0x20        /* (CKGR) Main Oscillator Register */
.equ CKGR_PLLAR,0x28        /* (CKGR) PLL A Register */
.equ PMC_MCKR,  0x30        /* (PMC) Master Clock Register */
.equ PMC_SR,	  0x68        /* (PMC) Status Register */

.text
.code 32

.global _error
_error:
  b _error

.global	_start
_start:

/* select system mode 
  CPSR[4:0]	Mode
  --------------
   10000	  User
   10001	  FIQ
   10010	  IRQ
   10011	  SVC
   10111	  Abort
   11011	  Undef
   11111	  System   
*/

  mrs r0, cpsr
  bic r0, r0, #0x1F   /* clear mode flags */  
  orr r0, r0, #0xDF   /* set supervisor mode + DISABLE IRQ, FIQ*/
  msr cpsr, r0     
  
  /* init stack */
  ldr sp,_Lstack_end
                                   
  /* setup system clocks */
  ldr r1, =PMC_BASE

  ldr r0, = 0x0F01
  str r0, [r1,#CKGR_MOR]

osc_lp:
  ldr r0, [r1,#PMC_SR]
  tst r0, #0x01
  beq osc_lp
  
  mov r0, #0x01
  str r0, [r1,#PMC_MCKR]

  ldr r0, =0x2000bf00 | ( 124 << 16) | 12  /* 18,432 MHz * 125 / 12 */
  str r0, [r1,#CKGR_PLLAR]

pll_lp:
  ldr r0, [r1,#PMC_SR]
  tst r0, #0x02
  beq pll_lp

  /* MCK = PCK/4 */
  ldr r0, =0x0202
  str r0, [r1,#PMC_MCKR]

mck_lp:
  ldr r0, [r1,#PMC_SR]
  tst r0, #0x08
  beq mck_lp

  /* Enable caches */
  mrc p15, 0, r0, c1, c0, 0 
  orr r0, r0, #(0x1 <<12) 
  orr r0, r0, #(0x1 <<2)
  mcr p15, 0, r0, c1, c0, 0 

.global _main
/* main program */
_main:

.equ PIOC_BASE, 0xFFFFF800 /* Zacetni naslov registrov za PIOC */
.equ PIO_PER, 0x00 /* Odmiki... */
.equ PIO_OER, 0x10
.equ PIO_SODR, 0x30
.equ PIO_CODR, 0x34

.equ PMC_BASE, 	0xFFFFFC00	/* Power Management Controller */
							/* Base Address */
.equ PMC_PCER, 	0x10  		/* Peripheral Clock Enable Register */

.equ TC0_BASE, 	0xFFFA0000	/* TC0 Channel Base Address */
.equ TC_CCR, 	0x00  		/* TC0 Channel Control Register */
.equ TC_CMR, 	0x04	  	/* TC0 Channel Mode Register*/
.equ TC_CV,    	0x10		/* TC0 Counter Value */
.equ TC_RA,    	0x14		/* TC0 Register A */
.equ TC_RB,    	0x18		/* TC0 Register B */
.equ TC_RC,    	0x1C		/* TC0 Register C */
.equ TC_SR,    	0x20		/* TC0 Status Register */
.equ TC_IER,   	0x24		/* TC0 Interrupt Enable Register*/
.equ TC_IDR,   	0x28		/* TC0 Interrupt Disable Register */
.equ TC_IMR,  	0x2C		/* TC0 Interrupt Mask Register */

.equ DBGU_BASE, 0xFFFFF200 /* Debug Unit Base Address */
.equ DBGU_CR, 0x00  /* DBGU Control Register */
.equ DBGU_MR, 0x04   /* DBGU Mode Register*/
.equ DBGU_IER, 0x08 /* DBGU Interrupt Enable Register*/
.equ DBGU_IDR, 0x0C /* DBGU Interrupt Disable Register */
.equ DBGU_IMR, 0x10 /* DBGU Interrupt Mask Register */
.equ DBGU_SR,  0x14 /* DBGU Status Register */
.equ DBGU_RHR, 0x18 /* DBGU Receive Holding Register */
.equ DBGU_THR, 0x1C /* DBGU Transmit Holding Register */
.equ DBGU_BRGR, 0x20 /* DBGU Baud Rate Generator Register */

   
      
      bl INIT_IO
      bl INIT_TC0
      bl DEBUG_INIT
      bl LED_OFF
     
          

INFINITE:
      adr r0,Testni
      bl SNDS_DEBUG
      
      adr r0,Received
      mov r1,#3
      bl RCVS_DEBUG
      adr r0, Received
      bl SNDS_DEBUG
      adr r0, Received
      bl XWORD
      b INFINITE
      
       

/* end user code */

_wait_for_ever:
  b _wait_for_ever
@---------------------------------------------
INIT_IO:
  stmfd r13!, {r0, r2, r14}
  ldr r2, =PIOC_BASE
  mov r0, #1 << 1
  str r0, [r2, #PIO_PER]
  str r0, [r2, #PIO_OER]
  ldmfd r13!, {r0, r2, pc}
  
INIT_TC0:

  stmfd r13!, {r0, r2, r14}
  
  ldr r2, =PMC_BASE  @bazni naslov 
  mov r0, #1 << 17
  str r0, [r2, #PMC_PCER]
  
  ldr r2, =TC0_BASE       @bazni naslov TC0
  mov r0, #0b110 << 13    @WAVE=1 WAVESEL=10
  add r0,r0,#0b011         @clock je 011
  str r0, [r2, #TC_CMR]
  
  ldr r0,=375             @register Rc je 375
  str r0, [r2, #TC_RC]
  
  mov r0,#0b101
  str r0, [r2, #TC_CCR]
  
  ldmfd r13!, {r0, r2, pc}
  

LED_ON:
  stmfd r13!, {r0, r2, r14}
  ldr r2, =PIOC_BASE
  mov r0, #1 << 1
  str r0, [r2, #PIO_CODR]
  ldmfd r13!, {r0, r2, pc}

LED_OFF:
  stmfd r13!, {r0, r2, r14}
  ldr r2, =PIOC_BASE
  mov r0, #1 << 1
  str r0, [r2, #PIO_SODR]
  ldmfd r13!, {r0, r2, pc}

@---------------------------------------------
DELAY:
  stmfd r13!, {r1,r2, lr}
  
  ldr r1, =TC0_BASE       
  LOOP:
    ldr r2, [r1, #TC_SR]   @go zima statusniot registar 
    tst r2, #0b10000       @proveruva dali 4tiot bit e 1, taka sto pravi maska 
    beq LOOP
    
  ldmfd r13!, {r1,r2, pc}
  
DELAY_TC:
  stmfd r13!, {r0, lr}     @msm ova e nepotrebno, kao celiov del
  ldr r0, =500
  LOOP_DELAY:
   bl DELAY
   sub r0,r0,#1
   cmp r0, #0
   bne LOOP_DELAY
   
  ldmfd r13!, {r0, pc}
  
@---------------------------------------------  
  
XMCHAR:
  stmfd r13!, {lr}
  cmp r0, #'.' 
  beq TOCKA
  cmp r0, #'-'
  beq CRTA 
  
  ldmfd r13!, {pc}
  
TOCKA:
  stmfd r13!, {lr}
  bl LED_ON
  bl KASNI_TOCKA 
  bl LED_OFF
  bl KASNI_CRTA
  ldmfd r13!, {pc}
  
CRTA:
  stmfd r13!, {lr}
  bl LED_ON
  bl KASNI_CRTA 
  bl LED_OFF
  bl KASNI_CRTA
  ldmfd r13!, {pc}  
  
  
KASNI_TOCKA:
  stmfd r13!, {r0, lr}
  ldr r0, =150
  LOOP_DELAY1:
   bl DELAY
   sub r0,r0,#1
   cmp r0, #0
   bne LOOP_DELAY1
  ldmfd r13!, {r0, pc}  
  
KASNI_CRTA:
  stmfd r13!, {r0, lr}
  ldr r0, =350
  LOOP_DELAY2:
   bl DELAY
   sub r0,r0,#1
   cmp r0, #0
   bne LOOP_DELAY2
   
  ldmfd r13!, {r0, pc}     
   
@--------------------------------
XMCODE:
  stmfd r13!, {lr}
  
  START:  
    ldrb r0,[r1]     @zima eden znak od celata niza
    cmp  r0,#0       @proveruva dali znakot e 0, ako e, skoka na END
    beq END
    bl XMCHAR        @odi da proveri sho znak e, za da znae kako da skoka
    add r1,r1,#1     @odi na sleden znak od nizata i se vraka na start
    b START
  END:
    bl KASNI_NIZA    @kasni 300ms 
       
  ldmfd r13!, {pc}
  
KASNI_NIZA:
  stmfd r13!, {r0, lr}
  ldr r0, =300
  LOOP_DELAY3:
   bl DELAY         @kasni 1ms
   sub r0,r0,#1     @kasni 300 pati za na kraj da e 300ms
   cmp r0, #0
   bne LOOP_DELAY3
  ldmfd r13!, {r0, pc}
  
@-------------------------------
GETMCODE:
  stmfd r13!, {r2,r3,r4,r5, r6,r7, lr}
  adr r7, CUVAJ   @zemi ja adresata kaj sho zacasno ke se cuvaat znacite
  adr r2, ZNAKI   @zemi ja tabelata so moris znacite
  mov r6, #6
  START1:
    ldrb r3,[r0]  @ja zima bukvata od nizata
    cmp r3,#0
    beq END1
    sub r3,r3,#65 @odzemi 65 za da doznaes koja zaporedna bukva e
    mul r3,r6     @mnozi so 6 za da dobies pocetok na bukvata vo ZANKA
    
  CITAJ_KOD:
    ldrb r4,[r2, r3] @go loadnuva prviot morsejev znak od bukvata
    cmp r4,#0        @proveruva dali e crta/tocka ili ne
    beq SLEDNA_BUKVA
    strb r4,[r7]
    add r7,r7,#1     @idi na sledna adresa od zacasno mesto za cuvanje
    add r3,r3,#1     @idi na sledna bukva od nizata
    b CITAJ_KOD
  SLEDNA_BUKVA:  
    add r0,r0,#1 @idi na sledna bukva
    b START1 
  
  END1:
    mov r4, #0
    add r7,r7,#1
    strb r4,[r7]
    adr r0, CUVAJ 
  ldmfd r13!, {r2,r3,r4,r5,r6,r7, pc}
  
@---------------------------------------------------
XWORD:
  stmfd r13!, {lr}
  bl GETMCODE
  mov r1, r0
  bl XMCODE
  bl KASNI_SEK 
  ldmfd r13!, {pc} 
  
KASNI_SEK:
  stmfd r13!, {r0, lr}
  ldr r0, =1000
  LOOP_DELAY4:
   bl DELAY
   sub r0,r0,#1
   cmp r0, #0
   bne LOOP_DELAY4
  ldmfd r13!, {r0, pc} 

@---------------------------------------------------  
DEBUG_INIT:
      stmfd r13!, {r0, r1, r14}
      ldr r0, =DBGU_BASE
      mov r1, #156        @  BR=19200
      str r1, [r0, #DBGU_BRGR]
      mov r1, #(1 << 11)
      str r1, [r0, #DBGU_MR]
      mov r1, #0b1010000
      str r1, [r0, #DBGU_CR]
      ldmfd r13!, {r0, r1, pc}

RCV_DEBUG:
      stmfd r13!, {r1, r14}
      ldr r1, =DBGU_BASE
RCVD_LP:
      ldr r0, [r1, #DBGU_SR]
      tst r0, #1
      beq RCVD_LP
      ldr r0, [r1, #DBGU_RHR]
      ldmfd r13!, {r1, pc}

SND_DEBUG:
      stmfd r13!, {r1, r2, r14}
      ldr r1, =DBGU_BASE
SNDD_LP:
      ldr r2, [r1, #DBGU_SR]
      tst r2, #(1 << 1)
      beq SNDD_LP
      str r0, [r1, #DBGU_THR]
      ldmfd r13!, {r1, r2, pc}

RCVS_DEBUG:
      stmfd r13!, {r1, r2, r14}
      mov r2, r0
RCVSD_LP:
      bl RCV_DEBUG
      cmp r0, #13
      beq KRAJ
      strb r0, [r2], #1
      b RCVSD_LP
      
KRAJ:      
      mov r0, #0
      strb r0, [r2]
      ldmfd r13!, {r1, r2, pc}

SNDS_DEBUG:
      stmfd r13!, {r2, r14}
      mov r2, r0
SNDSD_LP:
      ldrb r0, [r2], #1
      cmp r0, #0
      beq SNDD_END
      bl SND_DEBUG
      b SNDSD_LP
SNDD_END:
      ldmfd r13!, {r2, pc} 


/* constants */

Testni:  .asciz "\nType string(max 100) to be sent to Morse Code\n"
.align
Received: .space 100

.align


ZNAKI:  .ascii ".-" @ A 
        .byte 0,0,0,0 
        
        .ascii "-..."@ B 
        .byte 0,0 
        
        .ascii "-·-·" @ C 
        .byte 0,0 
        
        .ascii "-.." @ D 
        .byte 0,0,0 
        
        .ascii "." @ E 
        .byte 0,0,0,0,0 
        
        .ascii "..-." @ F 
        .byte 0,0 
        
        .ascii "--." @ G 
        .byte 0,0,0 
        
        .ascii "...." @ H 
        .byte 0,0 
        
        .ascii ".." @ I 
        .byte 0,0,0,0 
        
        .ascii ".---" @ J 
        .byte 0,0 
        
        .ascii "-.-" @ K 
        .byte 0,0,0 
        
        .ascii ".-.." @ L 
        .byte 0,0 
        
        .ascii "--" @ M 
        .byte 0,0,0,0 
        
        .ascii "-." @ N 
        .byte 0,0,0,0 
        
        .ascii "---" @ O 
        .byte 0,0,0 
        
        .ascii ".--." @ P 
        .byte 0,0 
        
        .ascii "--.-" @ Q 
        .byte 0,0 
        
        .ascii ".-." @ R 
        .byte 0,0,0 
        
        .ascii "..." @ S 
        .byte 0,0,0 
        
        .ascii "-" @ T 
        .byte 0,0,0,0,0 
        
        .ascii "..-" @ U 
        .byte 0,0,0 
        
        .ascii "...-" @ V 
        .byte 0,0 
        
        .ascii ".--" @ W 
        .byte 0,0,0 
        
        .ascii "-..-" @ X 
        .byte 0,0 
        
        .ascii "-.--" @ Y 
        .byte 0,0 
        
        .ascii "--.." @ Z 
        .byte 0,0
        
.align

CUVAJ:   .space 150          

_Lstack_end:
  .long __STACK_END__

.end

