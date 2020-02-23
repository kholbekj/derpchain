require "kemal"
require "./block"

module Crystal::Blockchain
  VERSION = "0.1.0"

  blockchain = [] of Block
  blockchain << Block.new(0, Time.local.to_s, ["I am creating 10 coins for Bob"], "")

  get "/" do
    blockchain.to_json
  end

  Kemal.run
end
