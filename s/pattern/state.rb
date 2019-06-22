# coding: utf-8

# Main purpose: State Machine!

# simple, static state
# only one state axis
class Player
  def initialize
    @state = :standing
  end

  def update
    send :"update_#@state"
  end

  def update_standing
    if Input.press? :DOWN
      @state = :ducking
      return
    end
  end

  def update_ducking
    unless Input.press? :DOWN
      @state = :standing
      return
    end
  end
end

# complex, push down state machine
class State
  def update target=nil
  end

  def enter target=nil
  end

  def leave target=nil
  end
end

class StandingState < State
  def update target
    if Input.press? :fire
      return FiringState.new # push new state
    end
    # ...
    return # nil = keep this state
  end
end

class FiringState < StandingState
  def update target
    # ...
    super
  end

  def should_pop?
    !(Input.press? :fire)
  end
end

class Player
  def initialize
    @states = [StandingState.new]
  end

  def state
    @states.last
  end

  def update
    if (_state = state.update self)
      state.leave
      _state.enter
      @states << _state
    elsif state.should_pop?
      @states.pop.leave
      state.enter
    end
  end
end
