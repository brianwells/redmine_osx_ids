class AddFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :auth_source_ref, :string
  end
  
  def self.down
    remove_column :users, :auth_source_ref
  end
end
