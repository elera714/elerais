OUTPUT_FORMAT("elf32-i386")

MEMORY
{    
    RAM (wx) : org = 0x000000100, len = 1M
}

SECTIONS
{
  .text 0x00000100:
  {
    . = ALIGN(32);
  }
  .data :
  {
	. = ALIGN(32);
  }
  .rodata :
  {
	. = ALIGN(32);
  }  
  .bss :
  {
	. = ALIGN(32);
  }
}