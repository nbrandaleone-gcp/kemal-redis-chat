require "kemal"
require "redis"
# require "log" ## Kemal includes logging

## Author: Nick Brandaleone nbrand@mac.com
## Date: December 2023
#
# This program is a web based chat program. It uses websockets
# to connect to client browsers and update messages. It uses
# Redis to handle the Pub/Sub mechanism.
#
# This program is intended to be run on Google Cloud Run,
# but can be run anywhere as long as a Redis database is available.
#
# Environmental Variables:
# REDIS - IP address or hostname of Redis DB. Defaults to localhost.
# PORT - TCP port of webserver. Defaults to 3000. Cloud Run uses 8080.
# DEBUG - a string boolean which turns on verbose logging
##

ENV["DEBUG"] ||= "false"
if ENV["DEBUG"] == "true"
  Log.setup(:debug)
end

Log.info { "Program started"}
# https://cloud.google.com/run/docs/container-contract
# The container instance can receive a SIGTERM signal indicating
# the start of a 10 second period before being shut down
# with a SIGKILL signal.

# Handle Ctrl+C (SIGTERM) and kill (SIGKILL) signal.
Signal::INT.trap  { puts "Caught Ctrl+C..."; exit }
Signal::TERM.trap { puts "Caught kill..."; exit }

# Redis requires a Channel for PubSub
CHANNEL = "chat"
SOCKETS = [] of HTTP::WebSocket

# redis client for publishing
# begin rescue end blocks can be used for safety
ENV["REDIS"] ||= "localhost"
#REDIS = Redis.new
REDIS = Redis.new(host: ENV["REDIS"], port: 6379)

# redis client for subscriptions or receiving of messages
spawn do
  redis_sub = Redis.new
  redis_sub.subscribe(CHANNEL) do |on|
    on.message do |channel, message|
      SOCKETS.each {|ws| ws.send(message) }
    end
  end
end

get "/" do
  render "views/index.ecr"
end

before_get "/api" do |env|
  puts "Setting response content type"
  env.response.content_type = "application/json"
end

get "/api" do |env|
  puts env.response.headers["Content-Type"]
  puts env.response.headers
  {name: "Kemal", awesome: true}.to_json
end

get "/history" do
end

get "/whereami" do
end

get "/shell" do
end

ws "/chat" do |socket|
  Log.debug { "In ws section" }
  SOCKETS << socket

  socket.on_message do |message|
    REDIS.publish(CHANNEL, message)
    Log.debug { "message: #{message}" }
  end

  socket.on_close do
    SOCKETS.delete socket
  end
end

# Kemal.config.port = ENV["PORT"].to_i || 3000
ENV["PORT"] ||= "3000"
Kemal.config.port = ENV["PORT"].to_i
Kemal.run
