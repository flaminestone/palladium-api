class Plan < Sequel::Model
  many_to_one :product
  one_to_many :runs
  plugin :validation_helpers
  self.raise_on_save_failure = false
  self.plugin :timestamps

  def validate
    super
    errors.add(:name, 'cannot be empty') if !name || name.empty?
  end

  def self.product_id_validation(plan, product_id)
    case
      when product_id.nil?
        plan.errors.add('product_id', "product_id can't be nil")
        return plan
      when product_id.empty?
        plan.errors.add('product_id', "product_id can't be empty")
        return plan
      when Product[id: product_id].nil?
        plan.errors.add('product_id', "product_id is not belongs to any product")
        return plan
    end
    plan
  end

  def self.plan_id_validation(plan_id)
    case
      when plan_id.nil?
        return {'plan_id': ["plan_id can't be nil"]}
      when plan_id.empty?
        return {'plan_id': ["plan_id can't be empty"]}
      when Plan[id: plan_id].nil?
        return {'plan_id': ["plan_id is not belongs to any product"]}
    end
    []
  end

  def self.create_new(data)
    data ||= {'name': ''}
    plan = self.new(name: data['name'])
    plan.valid? # update errors stack
    plan = self.product_id_validation(plan, data['product_id'])
    if plan.errors.empty?
      plan.save
      Product[id: data['product_id']].add_plan(plan)
    end
    plan
  end
end