require "kemal"
require "./block"

module Crystal::Blockchain
  VERSION = "0.1.0"

  PORTS = [1111, 1112, 1113]
  my_port = ARGV.any? ? ARGV.first.to_i : 3000
  other_ports = PORTS.select { |p| p != my_port }

  blockchain = [] of Block
  blockchain << Block.new(0, Time.local.to_s, ["I am creating 10 coins for Bob"], "")
  channel = Channel(String).new

  get "/" do
    blockchain.to_json
  end

  post "/add_transaction" do |env|
    sender = env.params.json["sender"].as(String)
    amount = env.params.json["amount"].as(Int64)
    recipient = env.params.json["recipient"].as(String)

    data = "I, #{sender}, am sending #{amount} coins to #{recipient}"
    channel.send(data)
    data
  end

  spawn do
    loop do
      block = Block.generate(blockchain.last, "I, Bob, am sending 5 coins to Alice", channel)
      blockchain << block if block.valid?(blockchain.last)
    end
  end

  spawn do
    loop do
      puts
      puts "Checking for new blocks"
      other_ports.each do |other_port|
        begin
          response = HTTP::Client.get "localhost:#{other_port}"
          body = JSON.parse(response.body)
          puts "Other chain is #{body.as_a.size} long"
          puts "My chain is #{blockchain.size} long"
          if body.as_a.size > blockchain.size
            puts "Importing..."
            new_blockchain = [] of Block
            body.as_a.each do |json_block|
              new_blockchain << Block.from_json(json_block)
              unless new_blockchain.size == 1 || new_blockchain.last.valid?(new_blockchain.last(2).first)
                puts "cheats!"
                puts new_blockchain.last.render
                puts new_blockchain.last(2).first.render
                raise "Other node is cheating!"
              end
            end
            blockchain = new_blockchain
            puts "Imported!"
          end
        rescue 
          puts "Can't connect to node with port #{other_port}"
        end
      end
      sleep 10
    end
  end

  Kemal.run(my_port)
end
