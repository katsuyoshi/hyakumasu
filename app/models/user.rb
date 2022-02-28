class User < ApplicationRecord

  STATE_IDLE = "idle"
  STATE_STARTED = "started"
  STATE_FINISHED = "finished"

  has_many :images, dependent: :destroy

  def col_numbers
    if self.col_numbers_str
      Marshal.load self.col_numbers_str
    else
      []
    end
  end
  
  def col_numbers= numbers
    self.col_numbers_str = Marshal.dump numbers
  end
  
  def row_numbers
    if self.row_numbers_str
      Marshal.load self.row_numbers_str
    else
      []
    end
  end

  def row_numbers= numbers
    self.row_numbers_str = Marshal.dump numbers
  end
  
  def answers
    if self.answers_str
      Marshal.load self.answers_str
    else
      []
    end
  end

  def answers= numbers
    self.answers_str = Marshal.dump numbers
  end
  
  def inputs
    if self.inputs_str
      Marshal.load self.inputs_str
    else
      []
    end
  end

  def inputs= numbers
    self.inputs_str = Marshal.dump numbers
  end


  # 問題開始
  def start
    self.level = 2
    n = self.level + 1
    q = 2.times.map{|i| n.times.map{|i| (1..9).to_a.sample}}
    self.col_numbers = q.first
    self.row_numbers = q.last

    a = []
    self.row_numbers.each do |r|
      self.col_numbers.each do |c|
        a << r * c
      end
    end
    self.answers = a

    self.images = []#.delete_all
    self.inputs = []

    self.save
  end

  def input number
    return finished?
    self.inputs << number
    self.save
  end

  def correct?
    self.inputs.last == self.answers[self.inputs.size - 1]
  end

  def correct_all?
    self.inputs == self.answers
  end

  def finished?
    self.inputs.size >= self.answers.size
  end

  def image at=nil
    img = images.at(at || inputs.size).first
p [:img, img]
    return img if img

    gen_image
    img = Image.new(data: File.read('tmp/result.png'), step: inputs.size)
    self.images << img
    img
  end

  def gen_image
p :gen_image
    l = self.level + 2
    len = 410
    w = h = (len-2) / l
    x0 = y0 = (len-2 - l * w) / 2 + 1
    color = '#000000'
    image = MiniMagick::Image.open('./app/assets/images/masu.png')
    image.combine_options do |c|
      l.times{|y| 
        l.times{|x|
          #c.stroke = color
          c.fill '#ffffff'
          c.stroke '#000000'
          cmd = "rectangle #{x0 + w * x},#{y0 + h * y} #{x0 + w * x + w},#{y0 + h * y + h}"
          c.draw cmd
        }
      }
    end
    fontsize = (w * 0.8).to_i
    col_numbers.each_with_index do |n, i|
      image.combine_options do |config|
        config.font "./app/assets/fonts/ZenOldMincho-Bold.ttf"
        config.pointsize fontsize
        config.fill '#000000'
        #config.gravity 'Center'
        #config.annotate
        config.draw "text #{x0 + (i + 1) * w + w / 2 - fontsize / 5},#{y0 + h - fontsize / 4} '#{n}'"
        config.draw "text #{x0 + w / 2 - fontsize / 5},#{y0 + (i + 2) * h - fontsize / 4} '#{row_numbers[i]}'"
      end
    end
    image.write "tmp/result.png"
    #send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
  end

end
