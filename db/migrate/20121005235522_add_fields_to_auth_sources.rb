class AddFieldsToAuthSources < ActiveRecord::Migration
    def up
        add_column :auth_sources, :osx_node_name, :string, :default => "", :null => false
        # column might be there from previous version of plugin
        AuthSource.reset_column_information
        unless column_exists?(:auth_sources, :restrict_access)
            add_column :auth_sources, :restrict_access, :boolean, :default => false, :null => false
        end
    end
    
    def down
        remove_column :auth_sources, :osx_node_name
        remove_column :auth_sources, :restrict_access
    end
end
