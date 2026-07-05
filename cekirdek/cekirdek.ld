OUTPUT_FORMAT("elf32-i386")

MEMORY
{    
    RAM (wx) : org = 0x00100000, len = 10M
}

SECTIONS
{
  .text 0x00100000:
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