BasicUpstart2(raster)

* = $4000
counter: .word 0
sleepDelay: .word 05
addrOffset: .byte 0
offsetCount: .word 0
testOffset: .word 200
screenPos: .byte 0
msgPos: .byte 0


//draw text macro
.macro drawText(msg, msgPosition, screenPosition) {
//main loop
cont:
  jsr checkChar
  ldx msgPosition
  lda msg,x
  inx
  stx msgPosition
  ldx screenPos
  sta screenPosition,x
  inx
  stx screenPos
  ldy #$00
  sty counter
  lda msg,x
  cmp #$0
  beq ret
  sleep(sleepDelay)
  jmp cont
checkChar:
  ldx msgPosition
  lda msg,x
  cmp #$03
  beq pause
  cmp #$00
  beq ret
  cmp #$01
  beq sleepChange
  stx msgPos
  rts
//
// .data 1 initializes a sleep
// the following .data is used for sleep in interrupts
// 50 = 1000ms
// 25 = 500ms
// msToFrames :: Milliseconds -> InterruptCycles
// msToFrames MS = (50/1000 * MS)
//
sleepChange:
  ldx msgPos
  inx
  lda msg,x
  sta sleepDelay
  inx 
  stx msgPos
  jmp checkChar
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
pause:
  jsr $ff9f
  jsr $ffe4
  cmp #$0
  beq pause
  ldx msgPos
  inx
  stx msgPos
  jmp checkChar
ret:
  lda #$0
  sta screenPos
  sta msgPos
}

.macro sleep(sleepTime) {
sleep:
  lda sleepTime
  cmp counter
  bne sleep
  
}

.macro setDelay(delay) {
  lda delay
  sta sleepDelay
}

//setup raster interrupt
//will make macro later for different required interrupts :)
int:
  jsr $ff9f
  jsr $ffe4
  cmp #$0
  inc $d019
  inc counter
  jmp $ea81

//initialize raster interrupt
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
//background changes
initMsg: 
  lda #$00
  sta $d020 //background
  sta $d021 //border
  lda #$01
  sta $0286 //cursor
  jsr $e544 //CLS
  ldx #$00
  jsr main
  jmp *

/////////////////////
      msg data
////////////////////
msg:
  .text "hello world"
  .byte $03
  .byte $01
  .byte $30
  .text "..."
  .byte $01
  .byte $05
  .text "test"
  .byte 0

msg2:
  .text "testing!"
  .byte 0
///////////////////////
     end msg data
///////////////////////


//example main
main:
  drawText(msg, msgPos, $0400)
  drawText(msg2,msgPos, $0500)
  rts


// quit
quit:
 jmp quit
