require "kemal"
require "./block"

module Crystal::Blockchain
  VERSION = "0.1.0"

  blockchain = [] of Block
  blockchain << Block.new(0, Time.local.to_s, ["I am creating 10 coins for Bob"], "")

  get "/" do
    blockchain.to_json
  end

  post "/add_transaction" do |env|
    sender = env.params.json["sender"].as(String)
    amount = env.params.json["amount"].as(Int64)
    recipient = env.params.json["recipient"].as(String)

    data = "I, #{sender}, am sending #{amount} coins to #{recipient}"
    data
  end

  spawn do
    loop do
      block = Block.generate(blockchain.last, "I, Bob, am sending 5 coins to Alice")
      blockchain << block if block.valid?(blockchain.last)
    end
  end

  Kemal.run
end
