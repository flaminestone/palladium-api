require 'net/http'
require 'json'
class ProductFunctions
  # @param [Hash] account like a {:email => 'email_from_account', :password => 'password_from_account'}
  # @param [String] name name for product. Max size = 30 simbols. If it empty - will be generate
  # return array with request and product name [request, product_name]
  def self.create_new_product(account, name = nil)
    product_name = 30.times.map { StaticData::ALPHABET.sample }.join if name.nil?
    request = Net::HTTP::Post.new('/product_new', 'Content-Type' => 'application/json')
    request.set_form_data({"user_data[email]": account[:email], "user_data[password]":  account[:password], "product_data[name]": product_name})
    [request, product_name]
  end

  # @param [Hash] account like a {:email => 'email_from_account', :password => 'password_from_account'}
  # return hash which keys - id of product, values - is a hash {'name': 'product_name'}
  def self.get_all_products(account)
    uri = URI(StaticData::MAINPAGE + '/products')
    params = {"user_data[email]": account[:email], "user_data[password]":  account[:password]}
    uri.query = URI.encode_www_form(params)
    hash_with_products = {}
    JSON.parse(Net::HTTP.get_response(uri).body)['products'].
        map {|current_product|
      hash_with_products.merge!({current_product['id'] => {"name" => current_product['name'],
                                                           "created_at" => current_product['created_at'],
                                                           "updated_at" => current_product['updated_at']}})}
    hash_with_products
  end
end