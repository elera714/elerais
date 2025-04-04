{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by the Free Pascal development team

    SetJmp and LongJmp implementation for exception handling

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

Function fpc_SetJmp (Var S : Jmp_buf) : longint;assembler;nostackframe;[Public, alias : 'FPC_SETJMP']; compilerproc;
asm
  //movl %ebx,Jmp_buf.ebx(%eax)
//  movl %esi,Jmp_buf.esi(%eax)
//  movl %edi,Jmp_buf.edi(%eax)
//  movl %ebp,Jmp_buf.bp(%eax)
//  leal 4(%esp),%edi
//  movl %edi,Jmp_buf.sp(%eax)
//  movl (%esp),%edi
//  movl %edi,Jmp_buf.pc(%eax)
{$ifdef FPC_USE_WIN32_SEH}
//  movl %fs:(0),%edi
//  movl %edi,Jmp_buf.exhead(%eax)
{$endif FPC_USE_WIN32_SEH}
//  movl Jmp_buf.edi(%eax),%edi
//  xorl %eax,%eax
end;


Procedure fpc_longJmp (Var S : Jmp_buf; value : longint); assembler;nostackframe;[Public, alias : 'FPC_LONGJMP']; compilerproc;
asm
  xchgl %edx,%eax
  cmpl  $1,%eax
  adcl  $0,%eax                  // if result<1 then inc(result) -- never return zero.
{$ifdef FPC_USE_WIN32_SEH}
  movl  Jmp_buf.exhead(%edx),%edi
  movl  %edi,%fs:(0)
{$endif FPC_USE_WIN32_SEH}
  movl Jmp_buf.ebx(%edx),%ebx
  movl Jmp_buf.esi(%edx),%esi
  movl Jmp_buf.edi(%edx),%edi
  movl Jmp_buf.bp(%edx),%ebp
  movl Jmp_buf.sp(%edx),%esp
  // we should also clear the fpu
  // fninit no must be done elsewhere PM
  // or we should reset the control word also
  jmp Jmp_buf.pc(%edx)
end;

