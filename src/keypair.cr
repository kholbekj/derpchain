require "openssl_ext/rsa"

class Keypair
  def self.generate(name)
    puts "Generating keys named #{name}"

    private_key = OpenSSL::RSA.new(32)
    puts private_key.to_pem
  end
end
