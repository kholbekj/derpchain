class Transaction
  def self.create_coinbase
    key_to_create_money_for = File.read("example_public.pem")
    coinbase_amount : Int64 = 10
    new(key_to_create_money_for, coinbase_amount)
  end

  def self.from_json(json_transaction : JSON::Any)
    new(
      json_transaction["recipient"].as_s,
      json_transaction["amount"].as_i64
    )
  end

  def initialize(@recipient : String, @amount : Int64)
  end

  def inspect(io)
    io << "#{@recipient} #{@amount}"
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "recipient" do
        @recipient.to_json(json)
      end

      json.field "amount" do
        @amount.to_json(json)
      end
    end
  end
end
