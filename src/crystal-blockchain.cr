require "kemal"
require "./block"
require "./node"
require "./keypair"
require "./transaction"
require "option_parser"

OptionParser.parse do |parser|
  parser.on "-v", "--version", "Show version" do
    puts "version 0.1"
    exit
  end

  parser.on "-g NAME", "--generate-keys", "Generate keypair" do |name|
    Keypair.generate(name)
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
    # sender = env.params.json["sender"].as(String)
    amount = env.params.json["amount"].as(Int64)
    recipient = env.params.json["recipient"].as(String)

    data = Transaction.new(recipient, amount)
    channel.send(data)
    data
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
