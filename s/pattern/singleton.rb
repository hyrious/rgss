# coding: utf-8

# Main purpose: some thing is designed to be only one

module OnlyOne
  @data = 42

  def self.data
    @data
  end

  def self.do_something
    # ...
  end
end

OnlyOne.do_something

# Stop using $global variables!
