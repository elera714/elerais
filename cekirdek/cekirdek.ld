OUTPUT_FORMAT("elf32-i386")

MEMORY
{    
    RAM (wx) : org = 0x00100000, len = 10M
}

INSERT AFTER .text;

SECTIONS
{
  .text 0x00100000 :
	{
		*(.text)
		*(.text.*)
		. = ALIGN(32);
	} > RAM
.data :
	{
		*(.data)
		*(.data.*)
		. = ALIGN(32);
	} > RAM
.rodata :
	{
		*(.rodata)
		*(.rodata.*)
		. = ALIGN(32);
	} > RAM
.bss :
	{
		*(.bss)
		*(COMMON)
		. = ALIGN(32);
	} > RAM
}