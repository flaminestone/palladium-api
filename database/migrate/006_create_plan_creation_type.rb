Sequel.migration do
  up do
    add_column :plans, :api_created, TrueClass, default: true
  end
end
