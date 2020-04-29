input.onButtonPressed(Button.A, function () {
  radio.sendString("input: A")
  led.toggle(3, 3)
})
input.onButtonPressed(Button.B, function () {
  radio.sendString("input: A")
  led.toggle(4, 3)
})
input.onButtonPressed(Button.AB, function () {
  radio.sendString("input: AB")
  led.toggle(3, 4)
})
input.onGesture(Gesture.Shake, function () {
  radio.sendString("input: shake")
  led.toggle(4, 4)
})
let pitch = 0
let lastPitch = 0
let roll = 0
let lastRoll = 0
let compass = 0
let lastCompass = 0
// JavaScript for a Microbit to transmit it's
// orientation and other input values via Radio to
// another Microbit
function compare(current: number, previous: number) {
  return Math.floor(current / 2.0) != Math.floor(previous / 2.0)
}
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
      led.toggle(0, 3)
  }
  roll = input.rotation(Rotation.Roll)
  if (compare(roll, lastRoll)) {
      radio.sendValue("roll", roll)
      lastRoll = roll
      led.toggle(1, 3)
  }
  compass = input.compassHeading()
  if (compare(compass, lastCompass)) {
      radio.sendValue("compass", compass)
      lastCompass = compass
      led.toggle(0, 4)
  }
  basic.pause(100)
})
