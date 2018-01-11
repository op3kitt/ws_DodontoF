#--*-coding:utf-8-*--

require 'hashie'

module AppConfig
  extend self

  def load(file)
    # default
    config = Hashie::Mash.new
    config.log = {
      level: Logger::ERROR,
      path: 'logs/log.txt'
    }
    config.host = "0.0.0.0"
    config.port = 8888

    config.secure = false
    config.tls_options = {
      private_key_file: "/private/key",
      cert_chain_file: "/ssl/certificate"
    }

    config.saveFileDir = 'saveData'

    config.saveLongChatLog = true
    config.longChatLogFile = 'chatLongLines.txt'

    config.useRecord = true

    config.saveFiles = {
      'chatMessageDataLog' => 'chat.json',
      'map' => 'map.json',
      'characters' => 'characters.json',
      'time' => 'time.json',
      'effects' => 'effects.json',
      'playRoomInfo' => 'playRoomInfo.json',
    }

    # overwirte
    instance_eval(file)

    config.each do |key, value|
      attr_accessor key
      send("#{key}=", value)
    end
  end

  AppConfig.load(File.read(File.expand_path('config/.config.rb')))

end