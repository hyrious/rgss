# coding: utf-8

# Main purpose: events, MVVM

module ObserverManager
  module_function

  def push observer
    @observers << observer
  end
  alias << push

  def notify event
    @observer.each { |ob| ob.notify event }
  end
end

module AchievementManager
  module_function

  def notify event
    case event
    when JumpEvent
      unlock :jump_1000 if (@jump_count += 1) >= 1000
    end
  end

  def unlock archievement
    return if @archievements.include?(archievement)
    @archievements << archievement
    puts "Unlocked [#{archievement}]!"
  end
end

ObserverManager << AchievementManager

class Player
  def jump
    # do jump
    ObserverManager.notify JumpEvent.new(self)
  end
end
