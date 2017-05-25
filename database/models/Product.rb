class Product < Sequel::Model
  one_to_many :plans
  plugin :validation_helpers
  plugin :association_dependencies
  self.add_association_dependencies :plans=>:destroy
  self.raise_on_save_failure = false
  plugin :timestamps, :force => true, :update_on_create => true, :create => :created_at

  def validate
    validates_unique :name
    validates_format /^.{1,30}$/, :name
  end

  def self.product_id_validation(product_id)
    case
      when product_id.nil?
        return {'product_id' => ["product_id can't be nil"]}
      when product_id.empty?
        return {'product_id' => ["product_id can't be empty"]}
      when Product[id: product_id].nil?
        return {'product_id' => ['product_id is not belongs to any product']}
    end
    {}
  end

  # def before_destroy
  #   super
  #   self.plans.dataset.destroy_all
  # end

  # @param [Hash] data must be like {:product_data => {name: 'product_name'}}
  # @return [ProductObject]
  def self.create_new(data)
    err_product = nil
    product_name = data['product_data']['name']
    new_product = Product.find_or_create(:name => product_name) {|product|
      product.name = data['product_data']['name']
      err_product = product unless product.valid?
    }
    err_product.nil? ? new_product : err_product
  end

  def self.edit(product_id, product_name)
    product = Product[:id => product_id]
    product.update(:name => product_name, :updated_at => Time.now)
    product.valid?
    {'product_data': product.values, 'errors': product.errors}.to_json
  end

  def self.get_plans(*args)
    product = if args.first['product_id']
                Product[:id => args.first['product_id']]
              elsif args.first['product_name']
                Product[:name => args.first['product_name']]
              end
    begin
      [product.plans, []]
    rescue StandardError
      [[], 'Plan data is incorrect']
    end
  end
end