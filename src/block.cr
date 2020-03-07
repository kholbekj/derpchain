class Block
  getter hash : String

  def self.generate(last_block, transaction_channel)
    block = Block.new(
      last_block.next_index,
      Time.local.to_s,
      [Transaction.create_coinbase],
      last_block.hash,
    )

    until block.hash_under_target?
      select 
      when transaction = transaction_channel.receive
        block.add_transaction!(transaction)
      else
      end

      block.increment_nonce!
    end

    puts "Mining complete! Solution: #{block.render}"
    block
  end

  def self.from_json(json_block : JSON::Any)
    data = json_block["data"].as_a.map {|t| Transaction.from_json(t) }
    Block.new(
      json_block["index"].as_i,
      json_block["timestamp"].as_s,
      data,
      json_block["prev_hash"].as_s,
      json_block["nonce"].as_i
    )
  end

  def initialize(@index : Int32, @timestamp : String, @data : Array(Transaction), @prev_hash : String, @nonce : Int32 = 0)
    @hash = calculate_hash
  end

  def calculate_hash : String
    sleep(0.01)
    plain_text = "
    #{@index}
    #{@timestamp}
    #{@data}
    #{@prev_hash}
    #{@nonce}
    "

    sha256 = OpenSSL::Digest.new("SHA256")
    sha256.update(plain_text)
    sha256.to_s
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "index" do
        @index.to_json(json)
      end
      json.field "timestamp" do
        @timestamp.to_json(json)
      end
      json.field "data" do
        @data.to_json(json)
      end
      json.field "prev_hash" do
        @prev_hash.to_json(json)
      end
      json.field "difficulty" do
        Block.difficulty.to_json(json)
      end
      json.field "nonce" do
        @nonce.to_json(json)
      end
      json.field "hash" do
        @hash.to_json(json)
      end
    end
  end

  def valid?(last_block : Block)
    return false unless @index == last_block.next_index
    return false unless @prev_hash == last_block.hash
    return false unless calculate_hash == @hash
    return hash_under_target?
  end

  def render
    "#{@hash} - #{@nonce}"
  end

  def hash_under_target?
    prefix = "0" * Block.difficulty
    @hash.starts_with?(prefix)
  end

  def increment_nonce!
    @nonce += 1
    @hash = calculate_hash
  end

  def next_index
    @index + 1
  end

  def add_transaction!(transaction : Transaction)
    @data << transaction
  end

  def self.difficulty
    3
  end
end
