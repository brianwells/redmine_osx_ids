class AddFieldsToAuthSources < ActiveRecord::Migration
  def self.up
    add_column :auth_sources, :osx_identity_authority, :string,
                              :default => "", :null => false
    add_column :auth_sources, :prefer_local_email, :boolean,
                              :default => true, :null => false
    add_column :auth_sources, :restrict_access, :boolean,
                              :default => false, :null => false
  end
  
  def self.down
    remove_column :auth_sources, :osx_identity_authority
    remove_column :auth_sources, :prefer_local_email
    remove_column :auth_sources, :restrict_access
  end
end
