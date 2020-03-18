# Intro

An experiment to use Microbits to control MIDI devices.

One Microbit acts as a [receiver](microbit/js/receiver.js) for others that [transmit](microbit/js/transmitter.js) values over radio.  It relays these to the serial bus (USB)

These are picked up by a Ruby [programme](ruby/src/microbit-reader.rb) and converted to MIDI controller values hardcoded for a Novation Bass Station synth and sent

# Setup

## Microbit

You need 2 of these.

Paste the code for the Transmitter into the [editor](https://makecode.microbit.org/#editor)
and download this to your Microbit.

Repeat for the Receiver and leave this one connected.  Connect the Transmitter to a set of batteries.

## Ruby

Run `cd ruby && bundle install` to add the required Gems.

In the ruby directory, run `ruby src/microbit-reader.rb` and chose a MIDI output (you need one of these).  If you move your Transmitter Microbit around, it will output the values it maps to the MIDI controllers and send to your synth.

# TODO

- Make the buttons and gestures do something.
- Make synth agnostic (configurable mapping of controls, e.g. 'learn')
- Allow ranges to be set for controllers, e.g. so we can restrict resonance, etc.
- Make Microbit transmit without 'throttling' - do this in the ruby code (was done to reduce sensitivity)
