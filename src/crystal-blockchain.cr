require "kemal"
require "./block"
require "./node"
require "./keypair"
require "./transaction"
require "option_parser"

new_transaction = Transaction.new

OptionParser.parse do |parser|
  parser.on "-v", "--version", "Show version" do
    puts "version 0.1"
    exit
  end

  parser.on "-g NAME", "--generate-keys", "Generate keypair" do |name|
    Keypair.generate(name)
    exit
  end

  parser.on "-r KEY", "--recipient KEY", "Specify transaction recipient" do |key|
    new_transaction.recipient = key
  end

  parser.on "-a AMOUNT", "--amount AMOUNT", "Specify transaction amount" do |amount|
    new_transaction.amount = amount.to_i64
  end

  parser.on "-n NONCE", "--nonce NONCE", "Specify transaction nonce" do |nonce|
    new_transaction.nonce = nonce
  end

  parser.on "-p PKEY_FILE", "--private-key PKEY_FILE", "Specify private key file" do |pkf|
    keypair = Keypair.load(pkf)
    new_transaction.keypair = keypair
  end

  parser.on "-t", "--transaction", "Create transaction" do
    unless new_transaction.valid_for_signing?
      puts "Transaction can't be created!" 
      exit
    end

    new_transaction.sign!
    new_transaction.print
    exit
  end
end

module Crystal::Blockchain
  VERSION = "0.1.0"

  PORTS = [1111, 1112, 1113]
  my_port = ARGV.any? ? ARGV.first.to_i : 3000
  other_nodes = PORTS.reject { |p| p == my_port }.map { |p| Node.new(p) }

  blockchain = [] of Block
  blockchain << Block.new(0, Time.local.to_s, [Transaction.create_coinbase], "")
  channel = Channel(Transaction).new

  get "/" do
    blockchain.to_json
  end

  post "/add_transaction" do |env|
    sender_key = env.params.json["sender_key"].as(String)
    nonce = env.params.json["nonce"].as(String)
    signature = env.params.json["signature"].as(String)
    amount = env.params.json["amount"].as(Int64)
    recipient_key = env.params.json["recipient_key"].as(String)

    transaction = Transaction.new(recipient_key, amount, sender_key, nonce, signature)
    halt env, status_code: 403, response: "Forbidden" unless transaction.valid_signature?
    halt env, status_code: 403, response: "Forbidden" unless transaction.funded?(blockchain.flat_map(&.transactions))

    channel.send(transaction)
    transaction
  end

  spawn do
    loop do
      block = Block.generate(blockchain.last, channel)
      blockchain << block if block.valid?(blockchain.last)
    end
  end

  spawn do
    loop do
      puts
      puts "Checking for new blocks"
      other_nodes.each do |node|
        node.get_chain
        puts "Other chain is #{node.chain_length} long" if node.reachable?
        puts "My chain is #{blockchain.size} long"
        if node.chain_length > blockchain.size
          puts "Importing..."
          blockchain = node.import_chain
          puts "Imported!"
        end
      end
      sleep 10
    end
  end

  Kemal.run(my_port)
end
