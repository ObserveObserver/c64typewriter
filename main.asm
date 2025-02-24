BasicUpstart2(raster)
.var music = LoadSid("Ahead_Crack_Intro.sid")


// zeropage pointers
*=$FA virtual
.zp {
    wrdPntLo: .byte 0
    wrdPntHi: .byte 0
    scrPntLo: .byte 0
    scrPntHi: .byte 0
    pntPntLo: .byte 0
    pntPntHi: .byte 0
}


* = $4000
counter: .word 0
sleepDelay: .word 01
addrOffset: .byte 0
offsetCount: .word 0
screenPos: .byte 0
msgPos: .byte 0
retPntPos: .byte 0
wordLen: .byte 0

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

ret:
    lda #$0
    sta screenPos
    sta msgPos
    rts

cont:
    jsr checkChar
    ldy msgPos
    lda (wrdPntLo),y
    cmp #$0
    beq ret
    iny
    sty msgPos
    ldy #$0
    sta (scrPntLo),y   // we require a screenPosition and msgPosition, as they fall out of sync.
                        // see if End of Screen :)
    inc scrPntLo
    bne noCarry
    inc scrPntHi
noCarry:
    lda scrPntLo
    cmp #$e7
    bne next
    lda scrPntHi
    cmp #$07
    bne next
    lda #<$0400
    sta scrPntLo
    lda #>$0400
    sta scrPntHi

next:  
    ldy msgPos
    lda (wrdPntLo),y
    cmp #$0
    beq ret
    ldy #$00
    sty counter
    sleep(sleepDelay)
    jmp cont

checkChar:      // checking our chars for sleep times and pauses
    ldy msgPos
    lda (wrdPntLo),y
    cmp #$ff
    beq pntr
    cmp #$fb
    beq pause3
    cmp #$fa
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

pntr:
    iny              
    lda (wrdPntLo),y
    sta pntPntLo
    iny
    lda (wrdPntLo),y
    sta pntPntHi
    iny
    iny
    iny
    sty msgPos
    ldy #$0
pntPrint:
    lda (pntPntLo),y
    beq pntDone
    pha             // Save character
    pla     
    ldy #$0         // Restore character
    sta (scrPntLo),y
    // see if End of Screen :)
    inc scrPntLo
    bne noCarry1
    inc scrPntHi
noCarry1:
    lda scrPntLo
    cmp $e7
    bne nextPnt
    lda scrPntHi
    cmp $07
    bne nextPnt
    lda #<$0400
    sta scrPntLo
    lda #>$0400
    sta scrPntHi
nextPnt:
    ldy wordLen
    iny
    sty wordLen
    ldx #$00
    stx counter
    sleep(sleepDelay)
    jmp pntPrint

pntDone:
    lda #$0
    sta wordLen
    rts

pause3: 
    jmp pause

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
    jsr music.play
    jmp $ea81

//initialize raster interrupt
raster:
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init
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
    drawText(msg2,$07E6)
    jmp main

// quit
quit1:
    jmp quit1

* = $5002
there: 
    .text "zxaby"
    .byte 0
msg:
    .text "hello world"
    .byte $fb    // pause until key pressed
    .byte $fa    // change sleep timer
    .byte $30    // sleep timer speed in interrupts
    .text "..."
    .byte $fa
    .byte toMs(50)
    .byte $ff
    .word there
    .byte $fa
    .byte toMs(200) // sleep timer speed in Ms
    .text " test"
    .byte 0

msg2:
    .byte $fa
    .byte toMs(50)
    .text "testing!"
    .byte 0

*=music.location "Music"
.fill music.size, music.getData(i)
