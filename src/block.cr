class Block
  @hash : String

  def initialize(@index : Int32, @timestamp : String, @data : String, @prev_hash : String)
    @nonce = 0
    @hash = calculate_hash
  end

  def calculate_hash : String
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

  def to_tuple
    {
      index: @index,
      timestamp: @timestamp,
      data: @data,
      prev_hash: @prev_hash,
      difficulty: Block.difficulty,
      nonce: @nonce,
      hash: @hash
    }
  end
  
  def self.create(index, timestamp, data, prev_hash, nonce)
    block = {
      index: index,
      timestamp: timestamp,
      data: data,
      prev_hash: prev_hash,
      difficulty: self.difficulty,
      nonce: nonce
    }
    block.merge({ hash: self.calculate_hash(block)})
  end

  def self.generate(last_block, data)
    current_block = self.create(
      last_block[:index] + 1,
      Time.local.to_s,
      data,
      last_block[:hash],
      0.to_s(16)
    )


    until hash_valid?(self.calculate_hash(current_block), current_block[:difficulty])
      puts "Mining! Trying another nonce... #{self.calculate_hash(current_block)}"
      current_block = current_block.merge({ nonce: (current_block[:nonce].to_i(16) + 1).to_s(16) })
    end

    puts "Mining complete! Nonce found: #{current_block[:nonce]}"
    current_block.merge({ hash: self.calculate_hash(current_block) })
  end

  def self.is_valid?(block, last_block)
    return false unless block[:index] == last_block[:index] + 1
    return false unless block[:prev_hash] == last_block[:hash]
    return false unless calculate_hash(block) == block[:hash]

    true
  end

  private def self.hash_valid?(hash, difficulty)
    prefix = "0" * difficulty
    hash.starts_with?(prefix)
  end

  private def self.calculate_hash(block)
    plain_text = "
      #{block[:index]}
      #{block[:timestamp]}
      #{block[:data]}
      #{block[:prev_hash]}
      #{block[:nonce]}
    "

    sha256 = OpenSSL::Digest.new("SHA256")
    sha256.update(plain_text)
    sha256.to_s
  end

  def self.difficulty
    3
  end
end
