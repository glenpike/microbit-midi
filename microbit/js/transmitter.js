// JavaScript for a Microbit to transmit it's orientation
// and other input values via Radio to another Microbit

function compare(current: number, previous: number) {
    return Math.floor(current / 2.0) != Math.floor(previous / 2.0)
}
input.onButtonPressed(Button.A, function () {
    radio.sendString("input: A")
})
input.onButtonPressed(Button.B, function () {
    radio.sendString("input: A")
})
input.onButtonPressed(Button.AB, function () {
    radio.sendString("input: AB")
})
input.onGesture(Gesture.Shake, function () {
    radio.sendString("input: shake")
})
let lastCompass = 0
let compass = 0
let lastRoll = 0
let roll = 0
let lastPitch = 0
let pitch = 0
basic.showLeds(`
    . . # . .
    . # # # .
    # . # . #
    . . # . .
    . . # . .
    `)
radio.setGroup(1)
radio.setTransmitSerialNumber(true)
basic.forever(function () {
    pitch = input.rotation(Rotation.Pitch)
    if (compare(pitch, lastPitch)) {
        radio.sendValue("pitch", pitch)
        lastPitch = pitch
    }
    roll = input.rotation(Rotation.Roll)
    if (compare(roll, lastRoll)) {
        radio.sendValue("roll", roll)
        lastRoll = roll
    }
    compass = input.compassHeading()
    if (compare(compass, lastCompass)) {
        radio.sendValue("compass", compass)
        lastCompass = compass
    }
    basic.pause(100)
})
