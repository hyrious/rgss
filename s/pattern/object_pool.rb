# coding: utf-8

# Main purpose: avoid realloc same objects

class Pool
  class Instance
    def initialize object
      @object = object
      @disposed = false
    end

    def dispose
      @disposed = true
    end

    def disposed?
      @disposed
    end

    def _undo_dispose
      @disposed = false
    end

    def _dispose
      @disposed = true
      @object.dispose
    end

    def method_missing(*a, &b)
      @object.send(*a, &b)
    ensure
      $@.shift if $@
    end
  end

  def initialize klass
    @klass = klass
    @pool = []
  end

  def allocate(*a, &b)
    if (instance = @pool.find &:disposed?)
      instance._undo_dispose
    else
      instance = Instance.new klass.new(*a, &b)
    end
    instance
  end

  def dispose
    @pool.each(&:_dispose).clear
  end
end

begin
  particle_pool = Pool.new Sprite
  10.times do
    particles = Array.new(10) { particle_pool.allocate viewport }
    particles.each(&:dispose) # not really dispose the sprites
  end
  particle_pool.dispose # really dispose the sprites
end
