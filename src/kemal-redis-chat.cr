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
Signal::INT.trap  { puts "Caught Ctrl+C..."; REDIS.close; exit }
#Signal::TERM.trap { puts "Caught kill..."; exit }

# Redis requires a Channel for PubSub
CHANNEL = "chat"
SOCKETS = [] of HTTP::WebSocket

# redis client for publishing
ENV["REDIS"] ||= "localhost"
Log.debug { "REDIS host is: #{ENV["REDIS"]}" }
#REDIS = Redis.new(host: ENV["REDIS"], port: 6379)
REDIS = Redis::PooledClient.new(host: ENV["REDIS"], port: 6379)

# redis client for subscriptions or receiving of messages
spawn do
  redis_sub = Redis::PooledClient.new(host: ENV["REDIS"], port: 6379)
  redis_sub.subscribe(CHANNEL) do |on|
    on.message do |channel, message|
      SOCKETS.each {|ws| ws.send(message) }
    end
  end
end

get "/" do
  render "views/index.ecr"
end

get "/ping" do
  REDIS.ping
end

get "/history" do
  Log.debug { "In /history section" }
  REDIS.lrange("history", 0, -1).to_s
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

get "/shell" do
  stdout = IO::Memory.new
  status = Process.run("ls", args: {"/"}, output: stdout)
  output = stdout.to_s
end

post "/msg" do |env|
  msg = env.params.json["msg"].as(String)
  Log.debug { "post: #{msg}" }
  REDIS.publish(CHANNEL, msg)
  REDIS.rpush("history", msg)
end

ws "/chat" do |socket|
  Log.debug { "In ws section" }
  SOCKETS << socket

  socket.on_message do |message|
    Log.debug { "message: #{message}" }
    REDIS.publish(CHANNEL, message)
    REDIS.rpush("history", message)
  end

  socket.on_close do
    SOCKETS.delete socket
  end
end

# Kemal.config.port = ENV["PORT"].to_i || 3000
ENV["PORT"] ||= "3000"
Kemal.config.port = ENV["PORT"].to_i
Kemal.run
