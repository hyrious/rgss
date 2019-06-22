# coding: utf-8

# Main purpose: clone & modify = new; reduce efforts on making database

class Data
  def derive attrs={}
    clone.tap { |o| attrs.each { |k, v| o.send :"#{k}=", v } }
  end
end

class Sword < Data
  attr_accessor :name, :length

  def initialize name, length
    @name = name
    @length = length
  end
end

sword = Sword.new 'Normal Sword', 2
long_sword = sword.derive name: 'Long Sword', length: 40

# In fact, there is Hash#merge..
sword = { type: :sword, name: 'Normal Sword', length: 2 }
long_sword = sword.merge name: 'Long Sword', length: 40

# Unless you're making database in code,
# GUI makes it easier to do copy & paste & modify.
