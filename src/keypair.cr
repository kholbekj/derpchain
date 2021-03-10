require "openssl_ext/rsa"

class Keypair
  def self.generate(name)
    puts "Generating keys named #{name}"

    private_key = OpenSSL::RSA.new(1024)
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

  def self.from_public_key(key)
    new(OpenSSL::RSA.new(key, nil, false))
  end

  def self.load(file_path)
    private_key_pem = File.read(file_path)
    new(OpenSSL::RSA.new(private_key_pem))
  end

  def initialize(@private_key : OpenSSL::RSA)
  end

  def check_signature(signature : String, hash : String)
    signature_array = signature.split(" ").map(&.to_i(16).to_u8)
    signature_slice = Bytes.new(signature_array.size)
    signature_slice.copy_from(signature_array.to_unsafe, signature_array.size)
    String.new(@private_key.public_decrypt(signature_slice)) == hash
  end

  def sign(string : String)
    @private_key.private_encrypt(string)
  end

  def public_key
    @private_key.public_key.to_pem
  end
end
