# coding: utf-8

# Main purpose: [Undo]

Player = Struct.new :x, :y

class MoveCommand
  def initialize target_x, target_y
    @target_x = target_x
    @target_y = target_y
  end

  attr_reader :target_x, :target_y

  def exec player
    @_x = player.x
    @_y = player.y
    player.x = target_x
    player.y = target_y
  end

  def undo
    player.x = @_x
    player.y = @_y
  end
end

# Some commands are stateless -- just re-use them in Flyweight pattern.
