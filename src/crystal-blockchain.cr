require "kemal"
require "./block"

module Crystal::Blockchain
  VERSION = "0.1.0"

  blockchain = [] of NamedTuple(
    index: Int32,
    timestamp: String,
    data: String,
    hash: String,
    prev_hash: String,
    difficulty: Int32,
    nonce: String
  )

  new_blockchain = [] of Block
  new_blockchain << Block.new(0, Time.local.to_s, "Instance Genesis!", "")
  blockchain << Block.create(0, Time.local.to_s, "Genesis block's data!", "", "0x1")

  get "/" do
    new_blockchain.map(&.to_tuple).to_json
  end

  post "/new_block" do |env|
    data = env.params.json["data"].as(String)

    new_block = Block.generate(blockchain.last, data)

    if Block.is_valid?(new_block, blockchain.last)
      blockchain << new_block
      puts
      p new_block
      puts
    end

  end

  Kemal.run
end
