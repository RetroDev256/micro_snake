/* This is a linker script to make tiny, but CORRECT programs */

ENTRY(_start)

PHDRS {
  text PT_LOAD FLAGS(5); /* R-X */
  data PT_LOAD FLAGS(6); /* RW- */
}

SECTIONS {
    . += SIZEOF_HEADERS;

    .text : SUBALIGN(0) {
        *(.text*)
        *(.rodata*)
    } :text

    .data : SUBALIGN(0) {
        *(.data*)
    } :data

    .bss : {
        *(.bss*)
        *(COMMON*)
    } :data

    /DISCARD/ : {
        *(.comment*)
        *(.eh_frame*)
        *(.eh_frame_hdr*)
    }
}