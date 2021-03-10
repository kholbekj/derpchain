class Transaction
  property sender_key : (String | Nil)
  setter nonce : (String | Nil)
  property signature : (String | Nil)
  property recipient : (String | Nil)
  property amount : (Int64 | Nil)
  @keypair : (Keypair | Nil)

  def self.create_coinbase
    key_to_create_money_for = File.read("example_public.pem")
    coinbase_amount : Int64 = 10
    new(key_to_create_money_for, coinbase_amount)
  end

  def self.from_json(json_transaction : JSON::Any)
    new(
      json_transaction["recipient_key"].as_s,
      json_transaction["amount"].as_i64,
      json_transaction["sender_key"].as_s?,
      json_transaction["nonce"].as_s?,
      json_transaction["signature"].as_s?,
    )
  end

  def initialize(@recipient = nil, @amount = nil, @sender_key = nil, @nonce = nil, @signature = nil)
  end

  def valid_for_signing?
    return unless @keypair && @recipient && @amount && @sender_key && @nonce && @recipient
    true
  end

  def valid_signature?
    return unless @amount && @nonce && @recipient
    sender_key = @sender_key
    signature = @signature
    return unless sender_key && signature
    Keypair.from_public_key(sender_key).check_signature(signature, hash)
  end

  def funded?(transactions : Array(Transaction))
    return unless sender_key = @sender_key
    return unless amount = @amount

    total_received_coins = transactions.select {|t| t.recipient == sender_key }.reduce(0.to_i64) { |sum, t| sum + (t.amount || 0) }
    total_spent_coins = transactions.select {|t| t.sender_key == sender_key }.reduce(0.to_i64) { |sum, t| sum + (t.amount || 0) }
    total_coins_available = total_received_coins - total_spent_coins
    puts "Total received: #{total_received_coins}"
    puts "Total spent: #{total_spent_coins}"
    puts "Transaction is funded" if total_coins_available > amount
    true if total_received_coins > amount
  end

  def hash
    digest = OpenSSL::Digest.new("SHA256")
    digest << "#{@recipient} #{@amount} #{@nonce}"
    digest.to_s
  end

  def sign!
    keypair = @keypair
    
    @signature = keypair.sign(hash).to_a.map(&.to_s(16)).join(" ") if keypair
  end

  def keypair=(keypair : Keypair)
    @sender_key ||= keypair.public_key
    @keypair = keypair
  end

  def print
    data =  {
      sender_key: @sender_key,
      recipient_key: @recipient,
      nonce: @nonce,
      signature: signature,
      amount: @amount,
    }.to_json

    puts data
  end

  def inspect(io)
    io << "#{@recipient} #{@amount}"
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "recipient_key" do
        @recipient.to_json(json)
      end

      json.field "amount" do
        @amount.to_json(json)
      end

      json.field "sender_key" do
        @sender_key.to_json(json)
      end

      json.field "nonce" do
        @nonce.to_json(json)
      end

      json.field "signature" do
        @signature.to_json(json)
      end
    end
  end
end
