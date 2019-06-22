# coding: utf-8

# Main purpose: component.update(self)

class GameObject
  def initialize *components
    @components = components
  end

  def update
    # careful, input.update should run before graphics.update
    @components.each { |comp| comp.update self }
  end
end
