BasicUpstart2(raster)

// zeropage pointers
*=$FB virtual
.zp {
wrdPntLo: .byte 0
wrdPntHi: .byte 0
scrPntLo: .byte 0
scrPntHi: .byte 0
}

// vars
* = $4000
counter: .word 0
sleepDelay: .word 05
addrOffset: .byte 0
offsetCount: .word 0
screenPos: .byte 0
msgPos: .byte 0

//     draw text
//
// .data 1 initializes a sleep
// the following .data is used for sleep in interrupts
// 50 = 1000ms
// 25 = 500ms
//
// .data 3 initializes a pause until any key is pressed
//
// .data 0 quits the macro call, all msgs must be 0-terminated!
//

// toMs :: Milliseconds -> InterruptCycles
.function toMs(X){
  .return round((50/1000)*X)  
}

cont:
  jsr checkChar
  ldy msgPos
  lda (wrdPntLo),y
  iny
  sty msgPos
  ldy screenPos
  sta (scrPntLo),y   // we require a screenPosition and msgPosition, as they fall out of sync.
  iny
  sty screenPos
  ldy #$00
  sty counter
  ldy msgPos
  lda (wrdPntLo),y
  cmp #$0
  beq ret
  sleep(sleepDelay)
  jmp cont
checkChar:      // checking our chars for sleep times and pauses
  ldy msgPos
  lda (wrdPntLo),y
  cmp #$03
  beq pause
  cmp #$00      // end of message (msgs must be 0 terminated!)
  beq ret
  cmp #$01
  beq sleepChange
  sty msgPos 
  rts
sleepChange:     // changes our sleep delay based on finding #$01
  ldy msgPos
  iny
  lda (wrdPntLo),y
  sta sleepDelay
  iny
  sty msgPos
  jmp checkChar
slower:
  setDelay(50)
  ldy msgPos
  iny
  sty msgPos
  jmp checkChar
faster:
  setDelay(25)
  ldy msgPos
  iny
  sty msgPos
  jmp checkChar
pause:
  jsr $ff9f
  jsr $ffe4
  cmp #$0
  beq pause
  ldy msgPos
  iny
  sty msgPos
  jmp checkChar
ret:
  lda #$0
  sta screenPos
  sta msgPos
  rts

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
initMsg: 
  lda #$00
  sta $d020 //background
  sta $d021 //border
  lda #$01
  sta $0286 //cursor
  jsr $e544 //CLS
  ldx #$00
  jsr main

// loads pointers for use in cont:
// can u believe oldheads had to write this out manually every time?
.macro drawText(msgInput, scr) {
  lda #<msgInput
  sta wrdPntLo
  lda #>msgInput
  sta wrdPntHi
  lda #<scr
  sta scrPntLo
  lda #>scr
  sta scrPntHi
  jsr cont
}

main:
  drawText(msg,$0400)
  drawText(msg2,$0600)
  jsr cont
  jmp quit1

// quit
quit1:
 jmp quit1

// messages
 * = $5002
 msg:
  .text "hello world"
  .byte $03    // pause until key pressed
  .byte $01    // change sleep timer
  .byte $30    // sleep timer speed in interrupts
  .text "..."
  .byte $01
  .byte toMs(200) // sleep timer speed in Ms
  .text "test"
  .byte 0

msg2:
  .byte $01
  .byte toMs(50)
  .text "testing!"
  .byte 0
