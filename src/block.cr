class Block
  getter hash : String

  def self.generate(last_block, data)
    block = Block.new(
      last_block.next_index,
      Time.local.to_s,
      data,
      last_block.hash,
    )

    until block.hash_under_target?
      puts "Mining! Not solution: #{block.render}"
      block.increment_nonce!
    end

    puts "Mining complete! Solution: #{block.render}"
    block
  end

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

  def self.difficulty
    3
  end
end
