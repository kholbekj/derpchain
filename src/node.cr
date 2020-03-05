class Node
  def initialize(@port : Int32)
    @body = [] of JSON::Any
  end

  def get_chain
    begin
      response = HTTP::Client.get "localhost:#{@port}"
      @body = JSON.parse(response.body).as_a
    rescue
      puts "Can't connect to node with port #{@port}"
    end
  end

  def chain_length
    @body.size
  end

  def import_chain
    new_blockchain = [] of Block
    @body.each do |json_block|
      new_blockchain << Block.from_json(json_block)
      unless new_blockchain.size == 1 || new_blockchain.last.valid?(new_blockchain.last(2).first)
        puts "cheats!"
        puts new_blockchain.last.render
        puts new_blockchain.last(2).first.render
        raise "Other node is cheating!"
      end
    end
    new_blockchain
  end
end
