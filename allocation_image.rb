require 'rubygems'
require 'cairo'

module AllocationImage 

  extend self

  def difference opts
    diffs = opts[:diffs]
    filename = opts[:filename]
    width = 1000

    num_columns = diffs.size
    column_width = width / num_columns
    column_width = 1 if column_width==0 # rounding grief

    cr = Cairo::Context.new(Cairo::ImageSurface.new(width,50))
    diffs.each_with_index do |diff, idx|
      colour = diff ? [1,1,1] : [0,0,0]
      cr.set_source_rgb(colour)
      lhs = idx * column_width
      rhs = lhs + column_width
      cr.rectangle(lhs,0, rhs,50)
      cr.fill()
    end
    cr.target.write_to_png(filename)

  end
  

  def generate opts
    vals = opts[:values]

    possible_vals = opts[:possible_values]
    val_to_hue = {}
    possible_vals.each_with_index do |val,idx|
      val_to_hue[val] = idx.to_f / possible_vals.size
    end

    filename = opts[:filename]
   
    width = 1000
    num_columns = vals.size
    column_width = width / num_columns
    column_width = 1 if column_width==0 # rounding grief

    cr = Cairo::Context.new(Cairo::ImageSurface.new(width,50))
    vals.each_with_index do |val, idx|
      colour = rgb_for_hue(val_to_hue[val])
      cr.set_source_rgb(*colour)
      lhs = idx * column_width
      rhs = lhs + column_width
      cr.rectangle(lhs,0, rhs,50)
      cr.fill()
    end
    cr.target.write_to_png(filename)
  end  
  
  def rgb_for_hue hue
    h2 = hue.to_f / (1.0/6)
    x = 1 - ((h2%2)-1).abs
    return [1,x,0] if h2<1
    return [x,1,0] if h2<2
    return [0,1,x] if h2<3
    return [0,x,1] if h2<4
    return [x,0,1] if h2<5
    return [1,0,x] # if h2<6
  end

end

