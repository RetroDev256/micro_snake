ENTRY(_start)
 
PHDRS {
  text PT_LOAD;
}

SECTIONS {
	. += SIZEOF_HEADERS;

	.text : SUBALIGN(0) {
		*(.text*)
		*(.rodata*)
		*(.data*)
		*(.bss*)
		*(COMMON*)
	}

	/DISCARD/ : {
		*(.comment*)
		*(.eh_frame*)
		*(.eh_frame_hdr*)
	}
}