# coding: utf-8

# Main purpose: more managers..

class Speaker
  def say text
    puts text
  end
end

class LoudSpeaker
  def say text
    puts text.upcase
  end
end

module Locator
  class << self
    attr_accessor :speaker
  end
end

Locator.speaker = Speaker.new

# ...

# careful, 'speaker' may be nil
Locator.speaker.say 'miaomiaomiao'

# to solve this, we may need an "empty" provider to do nothing
class BlackHole
  def method_missing(*a, &b)
    puts "BLACK HOLE: #{a.inspect}"
  end
end

Locator.speaker = BlackHole.new
