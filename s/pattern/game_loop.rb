# coding: utf-8

# Main purpose: this is how RGSS works

def mainloop
  loop do
    Input.update
    yield
    Graphics.update # will force Game.exe run in specific FPS
  end
end
