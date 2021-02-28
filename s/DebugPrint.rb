# coding: utf-8
#==============================================================================
# DebugPrint.rb
#==============================================================================
# @plugindesc Helper method to quickly do "p".
# @author hyrious
# @example
#
# dp def add(x, y)
#   return x + y
# end
# add 3, 5
#
# it prints:
# [dp] add(3, 5) => 8
#
# @help This plugin does not provide plugin commands.

module DebugPrint
  class << self
    attr_accessor :indent
  end
  DebugPrint.indent = 0

  def dp *args
    if args.size == 1 and args[0].is_a? Symbol
      meth = args[0]
      old = instance_method meth
      define_method meth do |*args, &block|
        DebugPrint.indent += 1
        old.bind(self).call(*args, &block).tap do |ret|
          DebugPrint.indent -= 1
          puts "[dp] #{' ' * DebugPrint.indent}#{meth}(#{args.map { |e| e.inspect }.join(', ')}) => #{ret.inspect}"
        end
      end
    else
      p *args
    end
  end

  Object.send :include, self
end
