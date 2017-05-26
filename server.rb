require_relative 'management'
class Api < Sinatra::Base
  # include Auth
  register Sinatra::CrossOrigin
  use JwtAuth

  def initialize
    super
  end

  before do
    content_type :json
    cross_origin
  end

  # ---- Products region ----
  get '/products' do
    process_request request, 'products' do |_req, _username|
      {products: Product.all.map(&:values)}.to_json
    end
  end

  post '/product_new' do
    process_request request, 'product_new' do |_req, _username|
      product = Product.create_new(params)
      {'product' => product.values, "errors" => product.errors}.to_json
    end
  end

  post '/product_edit' do
    process_request request, 'product_edit' do |_req, _username|
      Product.edit(params['product_data']['id'], params['product_data']['name'])
    end
  end

  post '/product_delete' do
    process_request request, 'product_delete' do |_req, _username|
      errors = Product.product_id_validation(params['product_data']['id'])
      if errors.empty?
        Product[:id => params['product_data']['id']].destroy
      end
      content_type :json
      status 200
      {'product': params['product_data']['id'], 'errors': errors}.to_json
    end
  end
  # ---- endregion ----

  # ---- Plans region ----

  post '/plan_new' do
    process_request request, 'plan_new' do |_req, _username|
      plan = Plan.create_new(params)
      status 422 unless plan.errors.empty?
      {'plan' => plan.values, "errors" => plan.errors}.to_json
    end
  end

  post '/plans' do
    process_request request, 'plans' do |_req, _username|
      plans, errors = Product.get_plans(params['plan_data'])
      status 422 unless errors
      {plans: plans.map(&:values), errors: errors}.to_json
    end
  end

  post '/plan_edit' do
    process_request request, 'plan_edit' do |_req, _username|
      plan = Plan.edit(params)
      status 422 unless plan['errors'].empty?
      plan
    end
  end
  # ---- endregion ----

  def process_request(req, scope)
    scopes, user = req.env.values_at :scopes, :user
    username = user['email']
    if scopes.include?(scope) && User.find(email: username).exists?
      yield req, username
    else
      halt 403
    end
  end
end

class Public < Sinatra::Base
  include Auth
  register Sinatra::CrossOrigin

  post '/login' do
    cross_origin
    if auth_success?(user_data)
      content_type :json
      {token: token(user_data['email'])}.to_json
    else
      halt 401
    end
  end


  get '/login' do
    erb :login
  end

  get '/registration' do
    erb :registration
  end

  # region auth
  get '/logout' do
    session[:user] = nil
    redirect '/'
  end

  post '/registration' do
    new_user = User.create_new(user_data)
    begin
      new_user.save if new_user.errors.empty?
    rescue
    end
    if new_user.errors.empty?
      session[:user] = user_data['email']
      status 200
    else
      status 201
      content_type :json
      new_user.errors.to_json
    end
  end

  def user_data
    params['user_data']
  rescue StandardError => error
    error
  end

  def token(email)
    JWT.encode payload(email), ENV['JWT_SECRET'], 'HS256'
  end

  def payload(email)
    {
        exp: Time.now.to_i + 60 * 60,
        iat: Time.now.to_i,
        iss: ENV['JWT_ISSUER'],
        scopes: %w(products product_new product_delete product_edit plan_new plans plan_edit),
        user: {
            email: email
        }
    }
  end
end
