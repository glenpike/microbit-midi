// Simple Microbit programme to act as a reciever
// - streams radio packets from other Microbits to 
// the serial output (which is USB)

radio.onReceivedValue(function (name, value) {
  radio.writeReceivedPacketToSerial()
  led.toggle(0, 4)
})
radio.onReceivedString(function (receivedString) {
  radio.writeReceivedPacketToSerial()
  led.toggle(4, 4)
})
basic.showIcon(IconNames.Pitchfork)
radio.setGroup(1)
