# encoding: utf-8
#!/usr/bin/env
# Needed channel CHANNEL - PANDA IHC
#testing channel CHANNEL
require 'net/http'
require "open-uri"
require 'nokogiri'
require 'rubygems'
require 'json'
require 'faye/websocket'
require 'eventmachine'

class Soccer
	def self.game_info
		answer_map = Hash.new 
		starting_count = false
		player_count = 0
		uri = URI.parse("https://slack.com/api/rtm.start")
		args = {token: 'TOKEN'}
		uri.query = URI.encode_www_form(args)
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true

		request = Net::HTTP::Get.new(uri.request_uri)

		response = http.request(request)
		parsed = JSON.parse(response.body)
		uri2 = parsed["url"]
		previousTime = 0

		EM.run {
			ws = Faye::WebSocket::Client.new(uri2.to_s)

			ws.on :open do |event|
				puts [:open]
			end

			ws.on :message do |event|
				data = JSON.parse(event.data)
				channel = data["channel"]
				current_day = Time.now.strftime("%A")
				current_time = ""
				current_time << Time.now.strftime("%H")
				current_time << Time.now.strftime("%M")
				current_time << Time.now.strftime("%S")
				puts data
				if current_day.eql? "Tuesday" and current_time.eql? "81800"
					starting_count = true
					answer_map = Hash.new
					message = "<!channel> Game tonight at 1055pm respond with yes or no now to get a running count."
					args = {token: 'TOKEN', channel: "CHANNEL", text: message, username:'Soccer bot'}
					botUri = URI.parse("https://slack.com/api/chat.postMessage")
					botUri.query = URI.encode_www_form(args)
					http = Net::HTTP.new(botUri.host, botUri.port)
					http.use_ssl = true
					request = Net::HTTP::Get.new(botUri.request_uri)
					response = http.request(request)
				end
				if !data["text"].nil?
					if starting_count and data["channel"].eql? "CHANNEL" and data["type"].eql? "message"
						if data["text"].upcase.eql? "YES" or data["text"].upcase.eql? "NO"
							user = data["user"]
							answer_map[user] = data["text"]
							if data["text"].upcase.eql? "YES"
								player_count += 1
							end
							puts answer_map
						end
					end
				end
				if current_day.eql? "Tuesday" and current_time.eql? "170000"
					starting_count = false
					answer_map = Hash.new
					player_count = 0
				end
				if data["text"].eql? "player count" and data["channel"].eql? "CHANNEL"
					message = "current count is "
					message << player_count.to_s
					args = {token: 'TOKEN', channel: "CHANNEL", text: message, username:'Soccer bot'}
					botUri = URI.parse("https://slack.com/api/chat.postMessage")
					botUri.query = URI.encode_www_form(args)
					http = Net::HTTP.new(botUri.host, botUri.port)
					http.use_ssl = true
					request = Net::HTTP::Get.new(botUri.request_uri)
					response = http.request(request)
				end
			end

			ws.on :close do |event|
				puts [:close, event.code, event.reason]
				ws = nil
			end
		}

	end
end
