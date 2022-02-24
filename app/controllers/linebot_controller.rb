class LinebotController < ApplicationController
  require 'line/bot'
  before_action :set_user, only: %i[ callback ]

  skip_before_action :verify_authenticity_token, only: ['callback']

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      render status: 400, json: { status: 400, message: 'Bad Request' }
    end
  
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = state_brach
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    end

    head :ok
  end

  def image
    send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
  end

  def preview_image
    send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
  end


=begin
  def image
    image = MiniMagick::Image.open('./app/assets/images/2x2.png')
    word = "縦書きですー"
    fontsize = 30
    color = '#000000'
    image.combine_options do |config|
      config.font "./app/assets/fonts/ZenOldMincho-Bold.ttf"
      config.pointsize fontsize
      config.fill color
      insert_vertical_word(word, 100, 100, fontsize, config)
    end
    image.write "tmp/result.png"
    send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
  end
=end


  private

  def client
    @client ||= Line::Bot::Client.new {|config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def state_brach
    res = ""
    set_user
    case @user.state || User::STATE_IDLE
    when User::STATE_IDLE
      res = state_idle
      #@user.state = User::STATE_STARTED
    when User::STATE_STARTED
      res = "答えてね"
      @user.state = User::STATE_FINISHED
    when User::STATE_FINISHED
      session[:state] = User::STATE_IDLE
      res = "終了"
      @user.state = User::STATE_IDLE
    end
    @user.save if @user.changed
    case res
    when String
      res = {
        type: 'text',
        text: res
      }
    end
    
p res
    res
  end

  def state_idle
    # 問題開始
    @user.level = 10
    n = @user.level + 1
    q = 2.times.map{|i| n.times.map{|i| (1..9).to_a.sample}}
    a = n.times.map{|i| [nil] * n}
    @user.col_numbers = q.first
    @user.row_numbers = q.last
    @user.save

    gen_masu_image

    {
      type: 'image',
      originalContentUrl: image_user_url(@user),
      previewImageUrl: preview_image_user_url(@user),
    }
  end


  def state_started
  end

  def state_finished
  end

  def gen_masu_image
    l = @user.level + 2
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
    @user.col_numbers.each_with_index do |n, i|
      image.combine_options do |config|
        config.font "./app/assets/fonts/ZenOldMincho-Bold.ttf"
        config.pointsize fontsize
        config.fill '#000000'
        #config.gravity 'Center'
        #config.annotate
        config.draw "text #{x0 + (i + 1) * w + w / 2 - fontsize / 5},#{y0 + h - fontsize / 4} '#{n}'"
        config.draw "text #{x0 + w / 2 - fontsize / 5},#{y0 + (i + 2) * h - fontsize / 4} '#{@user.row_numbers[i]}'"
      end
    end

    image.write "tmp/result.png"
    send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
  end


  # 一文字ずつ文字を設定していきます。伸ばし棒は９０度回転させています。
  def insert_vertical_word(word, x, y, fontsize, config)
    word.chars.each_with_index do |c, i|
      if c == "ー"
        config.gravity 'SouthWest'
        config.rotate -90
        config.draw "text #{y + i * fontsize + fontsize / 4},#{x - fontsize / 5} '#{c}'"
        config.rotate 90
      else
        config.gravity 'NorthWest'
        config.draw "text #{x},#{y + i * fontsize} '#{c}'"
      end
    end
  end

  def server_url
    ENV["SERVER_URL"] || "https://hyakumasu.herokuapp.com"
  end

  def preview_image_url
    "#{server_url}/line/preview_image"
  end

  def image_url
    "#{server_url}/line/image"
  end

  
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find_or_create_by(user_id: user_params[:events].first[:source][:userId])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.permit(:destination, events: [ :type, :timestamp, :replyToken, :mode, message: [:type, :id, :text], source:[:type, :userId] ])
  end
  
end
