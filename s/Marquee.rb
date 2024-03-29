# coding: utf-8
#==============================================================================
# Marquee.rb
#==============================================================================
# @plugindesc Show marquee on long items in Window_Command
# @author hyrious

class Window_Command < Window_Selectable
  alias _marquee_refresh refresh
  def refresh
    @marquee = []
    _marquee_refresh
  end

  alias _marquee_draw_item draw_item
  def draw_item(index)
    text = command_name(index)
    size = text_size(text); size.width += 2 # Fix actual width because of outline
    rect = item_rect_for_text(index)
    if rect.width < size.width
      b = Bitmap.new(size.width, size.height)
      b.draw_text(b.rect, command_name(index))
      @marquee << [index, 0, size.width - rect.width, 1, b]
    else
      _marquee_draw_item(index)
    end
  end

  alias _marquee_update update
  def update
    _marquee_update
    @marquee.each { |e|
      e[1] += e[3]
      e[3] = -1 if e[3] > 0 and e[1] >= e[2]
      e[3] = +1 if e[3] < 0 and e[1] <= 0
      _draw_marquee_item(e[0], e[1], e[4])
    }
    # If you want "only scroll the selected item", use the code below
    # @marquee.each { |e|
    #   if e[0] == index
    #     e[1] += e[3]
    #     e[3] = -1 if e[3] > 0 and e[1] >= e[2]
    #     e[3] = +1 if e[3] < 0 and e[1] <= 0
    #   else
    #     e[1] = 0; e[3] = 1
    #   end
    #   _draw_marquee_item(e[0], e[1], e[4])
    # }
  end

  def _draw_marquee_item(index, dx, b)
    clear_item(index)
    change_color(normal_color, command_enabled?(index))
    dst = item_rect_for_text(index)
    src = b.rect.clone; src.x += dx
    contents.blt(dst.x, dst.y, b, src)
  end
end
