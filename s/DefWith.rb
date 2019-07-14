# coding: utf-8
#==============================================================================
# DefWith.rb
#==============================================================================
# @plugindesc Replacement of `alias`.
# @author hyrious
#
# @help This plugin does not provide plugin commands.

module DefWith
  def def_with meth, &blk
    old = instance_method meth
    define_method meth do |*args, &block|
      blk.call old.bind(self), *args, &block
    end
  end

  Object.send :include, self
end
