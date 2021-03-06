require 'fileutils'
include FileUtils

class User < ApplicationRecord

  STATE_IDLE = "idle"
  STATE_STARTED = "started"
  STATE_FINISHED = "finished"

  has_many :images, dependent: :destroy

  def col_numbers
    (col_numbers_str || "").split(',').map(&:to_i)
  end
  
  def col_numbers= numbers
    self.col_numbers_str = numbers.map(&:to_s).join(',')
  end
  
  def row_numbers
    (row_numbers_str || "").split(',').map(&:to_i)
  end

  def row_numbers= numbers
    self.row_numbers_str = numbers.map(&:to_s).join(',')
  end
  
  def answers
    (answers_str || "").split(',').map(&:to_i)
  end

  def answers= numbers
    self.answers_str = numbers.map(&:to_s).join(',')
  end
  
  def inputs
    (inputs_str || "").split(',').map(&:to_i)
  end

  def inputs= numbers
    self.inputs_str = numbers.map(&:to_s).join(',')
  end


  # 問題開始
  def start
    self.level = 2
    n = self.level
    q = 2.times.map{|i| n.times.map{|i| (1..9).to_a.sample}}
    self.col_numbers = q.first
    self.row_numbers = q.last

    a = []
    self.row_numbers.each do |r|
      self.col_numbers.each do |c|
        a << r + c
      end
    end
    self.answers = a

    self.images = []
    self.inputs = []

p self
    self.save
  end

  def input number
    return if finished?
    self.inputs = self.inputs + [number]
    self.save
  end

  def correct? at=nil
    at ||= [self.inputs.size - 1, 0].max
    self.inputs[at] == self.answers[at]
  end

  def correct_all?
    self.inputs == self.answers
  end

  def finished?
    self.inputs.size >= self.answers.size
  end

  def image at=nil
    step = at || self.step
    step = step.to_i
    img = images.at(at || step).first
    return img if img

    gen_image
    img = Image.create(user_id: self.id, data: File.read(image_file_path(step)), step: at)
    self.images << img
    img
  end

  def gen_image no=nil
    no ||= self.step
    l = self.level
    len = 410
    w = h = (len-2) / (l + 1)
    x0 = y0 = (len-2 - (l + 1) * w) / 2 + 1
    color = '#000000'
    image = MiniMagick::Image.open(base_image_path)
    r0 = no / l
    c0 = no % l
    # 枠と現在の加算箇所に丸印をつける
    image.combine_options do |c|
      (l + 1).times{|y| 
        (l + 1).times{|x|
          #c.stroke = color
          c.fill '#ffffff'
          c.stroke '#000000'
          cmd = "rectangle #{x0 + w * x},#{y0 + h * y} #{x0 + w * x + w},#{y0 + h * y + h}"
          c.draw cmd
          if !finished? && (
             (y == 0 && (c0 + 1) == x) ||
             (x == 0 && (r0 + 1) == y) ||
             ((x == (c0 + 1)) && (y == (r0 + 1)))
            )
            cx = x0 + w * x + w / 2
            cy = y0 + h * y + h / 2
            cmd = "circle #{cx},#{cy} #{cx + w/3},#{cy+ h/3}"
            c.draw cmd
          end
        }
      }
    end
    
    # 問題の数字を書き込み
    fontsize = (w * 0.8).to_i
    col_numbers.each_with_index do |n, i|
      image.combine_options do |config|
        config.font font_path
        config.pointsize fontsize
        config.fill '#000000'
        #config.gravity 'Center'
        #config.annotate
        x_offset = -6
        config.draw "text #{x0 + x_offset + (i + 1) * w + w / 2 - fontsize / 5},#{y0 + h - fontsize / 4} '#{n}'"
        config.draw "text #{x0 + x_offset+ w / 2 - fontsize / 5},#{y0 + (i + 2) * h - fontsize / 4} '#{row_numbers[i]}'"
      end
    end

    # 回答を書き込み
    inputs.each_with_index do |n, i|
      i = i.to_i
      y = i / l + 2
      x = i % l + 1
      image.combine_options do |config|
        config.font font_path
        config.pointsize fontsize
        config.fill '#000000'
        #config.gravity 'Center'
        #config.annotate
        case n.to_s.length
        when 2
          x_offset = -38
        else
          x_offset = -15
        end

        unless finished?
          config.fill '#000000'
          config.stroke '#000000'
        else
          if correct?(i)
            config.fill '#00ff00'
            config.stroke '#000000'
          else
            config.fill '#ff0000'
            config.stroke '#000000'
          end
        end
        config.draw "text #{x0 + x_offset + x * w + w / 2 - fontsize / 5},#{y0 + y * h - fontsize / 4} '#{n}'"
      end
    end

    image.combine_options do |config|
      config.font font_path
      config.pointsize fontsize
      if finished?
        if correct_all?
          config.fill '#00ff00'
          config.stroke '#000000'
          config.draw "text 100,120 '正解'"
        else
          config.fill '#ff0000'
          config.stroke '#000000'
          #config.draw "text 50,120 '不正解'"
          config.draw "text 50,120 'おしい'"
        end
      end
    end

    image.write image_file_path
  end

  def step
    self.inputs.size || 0
  end

  def base_image_path
    './app/assets/images/masu.png'
  end

  def font_path
    "./app/assets/fonts/ZenOldMincho-Bold.ttf"
  end

  def image_file_path step=nil
    step ||= self.step
    path = "tmp/#{self.id}/result_#{step}.png"
    mkdir_p File.dirname(path)
    path
  end

end
