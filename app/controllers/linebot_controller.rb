class LinebotController < ApplicationController
  require 'line/bot'
  before_action :set_user, only: %i[ callback image preview_image ]

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
          message = state_branch
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
    #send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
    send_data(@user.image.data, filename: 'image.jpg', disposition: 'attachment')
  end

  def preview_image
    #send_file 'tmp/result.png', type: 'image/png', disposition: 'inline'
    send_data(@user.image.data, filename: 'image.jpg', disposition: 'attachment')
  end


  private

  def client
    @client ||= Line::Bot::Client.new {|config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def state_branch
    res = ""
    set_user
    case @user.state || User::STATE_IDLE
    when User::STATE_IDLE
      res = state_idle
      @user.state = User::STATE_STARTED
    when User::STATE_STARTED
      res = state_started
      @user.state = User::STATE_IDLE if @user.finished?
    when User::STATE_FINISHED
      res = state_finished
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
    
    res
  end

  def state_idle
    # 問題開始
    @user.level = 10
    @user.start
    {
      type: 'image',
      originalContentUrl: "#{server_url}#{image_user_path(@user, step: @user.step)}",
      previewImageUrl: "#{server_url}#{preview_image_user_path(@user, step: @user.step)}",
    }
  end

  def state_started
    inp = params[:events].first[:message][:text]
    if /(\d+)/ =~ inp
      @user.input $1.to_i
      if @user.finished?
        state_finished
      else
        {
          type: 'image',
          originalContentUrl: "#{server_url}#{image_user_path(@user, step: @user.step)}",
          previewImageUrl: "#{server_url}#{preview_image_user_path(@user, step: @user.step)}",
        }
      end
    else
      "すうじでこたえてね。"
    end
  end

  def state_finished
    {
      type: 'image',
      originalContentUrl: "#{server_url}#{image_user_path(@user, step: @user.step)}",
      previewImageUrl: "#{server_url}#{preview_image_user_path(@user, step: @user.step)}",
    }
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
    @user = User.find_or_create_by(user_id: user_params[:events].first[:source][:userId]) if user_params[:events]
    @user ||= User.first
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.permit(:destination, events: [ :type, :timestamp, :replyToken, :mode, message: [:type, :id, :text], source:[:type, :userId] ])
  end
  
end
