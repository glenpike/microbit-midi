// Simple Microbit programme to act as a reciever
// - streams radio packets from other Microbits to 
// the serial output (which is USB)

radio.onReceivedValue(function (name, value) {
  radio.writeReceivedPacketToSerial()
})
radio.onReceivedString(function (receivedString) {
  radio.writeReceivedPacketToSerial()
})
basic.showIcon(IconNames.Pitchfork)
radio.setGroup(1)
