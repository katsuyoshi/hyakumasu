class LinebotController < ApplicationController
  require 'line/bot'
  
  skip_before_action :verify_authenticity_token

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
          message = {
            type: 'text',
            text: state_brach #'もう夜か...' #event.message['text']
          }
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

  private

  def client
    @client ||= Line::Bot::Client.new {|config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def state_brach
    case session[:state] || :idle
    when :idle
      session[:state] = :started
      state_idle
    when :started
      session[:state] = :finished
      "答えてね"
    when :finished
      session[:state] = :idle
      "終了"
    end
  end

  def state_idle
    n = (session[:level] || 1) + 1
    q = 2.times.map{|i| n.times.map{|i| (1..9).to_a.sample}}
    a = n.times.map{|i| [nil] * n}
    session[:question] = q
    session[:answer] = a

    messages = ["問題は"]
    messages << "\\ " + q.first.join(" ")
    q.last.each do |v|
      messages << v.to_s
    end
    messages.join("\n")
  end

  def state_started
  end

  def state_finished
  end

end
