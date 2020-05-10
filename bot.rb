require 'telegram/bot'
require 'active_support/all'

require_relative './utils'

include ActiveSupport::NumberHelper

data = Utils.run_query(Utils.query_places)
valid_locations = data.map{|h| h['ccaa']}

Telegram::Bot::Client.run(ENV['TOKEN'], logger: Logger.new($stderr)) do |bot|
  bot.listen do |message|
    text = message.text.strip
    if text =~ /\Adatos/
      if m = text.match(/\Adatos\s(.+)\z/)
        autonomy = m[1].try(:strip)
        if valid_locations.include?(autonomy)
          answer = Utils.parse_data(Utils.run_query(Utils.query_data(autonomy)), autonomy)
          bot.api.send_message(chat_id: message.chat.id, text: answer)
        else
          bot.api.send_message(chat_id: message.chat.id, text: "Por favor, introduce una autonomía válida. Opciones:")
          bot.api.send_message(chat_id: message.chat.id, text: valid_locations.join("\n"))
        end
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Por favor, introduce la autonomía. Opciones")
        bot.api.send_message(chat_id: message.chat.id, text: valid_locations.join("\n"))
      end
    elsif %(comunidades autonomias autonomías).include?(text.try(:downcase))
      bot.api.send_message(chat_id: message.chat.id, text: "Comunidades autónomas disponibles:")
      bot.api.send_message(chat_id: message.chat.id, text: valid_locations.join("\n"))
    elsif text.try(:downcase) == "acercade"
      bot.api.send_message(chat_id: message.chat.id, text: Utils.about_message)
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Comandos:")
      bot.api.send_message(chat_id: message.chat.id, text: "- datos <Autonomia>, donde autonomía es uno de estos valores: #{valid_locations.join(', ')}")
      bot.api.send_message(chat_id: message.chat.id, text: "- comunidades o autonomías, para obtener un listado de valores")
      bot.api.send_message(chat_id: message.chat.id, text: "- acercade, para saber más sobre el bot y los datos")
    end
  end
end
