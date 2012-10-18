class AddFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :osx_record_guid, :string
  end
end
