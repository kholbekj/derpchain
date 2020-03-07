require "openssl_ext/rsa"

class Keypair
  def self.generate(name)
    puts "Generating keys named #{name}"

    private_key = OpenSSL::RSA.new(512)
    private_pem = private_key.to_pem
    public_pem = private_key.public_key.to_pem

    private_path = "#{name}_private.pem"
    public_path = "#{name}_public.pem"

    if File.exists?(public_path) || File.exists?(private_path)
      puts "Keys already present, abandoning!"
    end

    File.write(private_path, private_pem)
    File.write(public_path, public_pem)
  end
end
