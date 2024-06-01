BasicUpstart2(raster)

* = $4000
counter: .word 0
sleepDelay: .word 05
addrOffset: .byte 0
offsetCount: .word 0
testOffset: .word 200

.macro sleep(sleepTime) {
sleep:
  lda sleepTime
  cmp counter
  beq cont
  jmp sleep
}

.macro setDelay(delay) {
  inx
  txa
  ldy testOffset
  sta $0400,y
  iny
  sty testOffset 
  lda delay
  sta sleepDelay
  rts
}

int:
  inc $d019
  inc counter
  jmp $ea81
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
initMsg: 
  lda #$00
  sta $d020
  sta $d021
  lda #$01
  sta $0286
  jsr $e544
  ldx #$00
  jsr cont
  jmp *
msg:
  .text "hello world"
  .byte $01
  .text "..."
  .byte $02
  .text "test"
  .byte 0
cont:
  lda msg,x
  sta $0400,x
  jsr checkNextChar
  ldy #$00
  sty counter
  sleep(sleepDelay)
checkNextChar:
  inx 
  lda msg,x
  cmp #$00
  beq quit
  cmp #$01  // Period check
  beq slower
  cmp #$02
  beq faster
  rts
slower:
  setDelay(50)
  rts
faster:
  setDelay(25)
  rts
// cases for various sleeps
quit:
 jmp quit