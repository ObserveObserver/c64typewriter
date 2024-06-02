BasicUpstart2(raster)

* = $4000
counter: .word 0
sleepDelay: .word 05
addrOffset: .byte 0
offsetCount: .word 0
testOffset: .word 200
screenPos: .byte 0
msgPos: .byte 0

.macro sleep(sleepTime) {
sleep:
  lda sleepTime
  cmp counter
  beq cont
  jmp sleep
}

.macro setDelay(delay) {
  lda delay
  sta sleepDelay
}

int:
  inc $d019
  inc counter // on interrupt, inc counter
  jmp $ea81
// setting raster interrupt
raster:
  sei
  lda #$7f
  sta $dc0d
  sta $dd0d
  and $d011
  sta $d011
  lda #100
  sta $d012
  lda #<int
  sta $0314
  lda #>int
  sta $0315
  lda #$01
  sta $d01a
  cli
// setting background and border
initMsg: 
  lda #$00
  sta $d020     // background
  sta $d021     // border
  lda #$01
  sta $0286     // cursor
  jsr $e544     // cls
  ldx #$00
  jsr cont
  jmp *

// msg data
// an alternative method would be:
// .text "hello world"
// .byte $01 (indicating a change in speed)
// .byte $## (where ## is our interrupts to sleep)
// [...]
// cmp #$01
// jeq sleepDelaySet
// sleepDelaySet:
// inx
// stx sleepDelay
// --
// Thus, our sleep delay is indicated in the msg itself. ill try this later :) its elegant.
msg:
  .text "hello world"
  .byte $03     //  byte 3 is pause
  .byte $01     //  byte 1 is slower 
  .text "..."
  .byte $02
  .text "test"
  .byte 0
// loop
cont:
  jsr checkChar
  ldx msgPos
  lda msg,x
  inx
  stx msgPos
  ldx screenPos
  sta $0400,x
  inx
  stx screenPos
  ldy #$00
  sty counter
  sleep(sleepDelay)
// checking char for speed and sleep-related data
checkChar:
  ldx msgPos
  lda msg,x
  cmp #$03
  beq pause
  cmp #$00
  beq quit
  cmp #$01  // Period check
  beq slower
  cmp #$02
  beq faster
  stx msgPos
  rts
slower:
  setDelay(50)
  ldx msgPos
  inx
  stx msgPos
  jmp checkChar
faster:
  setDelay(25)
  ldx msgPos
  inx
  stx msgPos
  jmp checkChar
// pause until any key is read
pause:
  jsr $ff9f
  jsr $ffe4
  cmp #$0
  beq pause
  ldx msgPos
  inx
  stx msgPos
  jmp checkChar
quit:
 jmp quit
