require "kemal"
require "./block"

module Crystal::Blockchain
  VERSION = "0.1.0"

  blockchain = [] of Block
  blockchain << Block.new(0, Time.local.to_s, "Instance Genesis!", "")

  get "/" do
    blockchain.map(&.to_tuple).to_json
  end

  post "/new_block" do |env|
    data = env.params.json["data"].as(String)

    new_block = Block.generate(blockchain.last, data)

    if new_block.valid?(blockchain.last)
      blockchain << new_block
      puts
      p new_block
      puts
    end

  end

  Kemal.run
end
