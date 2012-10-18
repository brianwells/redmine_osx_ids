namespace :redmine_osx_ids do
  desc "Migrate Identity Services data to Open Directory data"
  task :migrate_data => :environment do
    if AuthSource.column_names.include? "osx_identity_authority"
        # convert auth_sources osx_identity_authority to osx_node_name
        AuthSourceOsx.find_each do |auth_source|
            if auth_source.osx_node_name.empty?
                if auth_source.osx_identity_authority == "default" || auth_source.osx_identity_authority == "managed"
                    auth_source.update_attribute :osx_node_name, "/Search"
                end
                if auth_source.osx_identity_authority == "local"
                    auth_source.update_attribute :osx_node_name, "/Local/Default"
                end
            end
        end
    end
    if User.column_names.include? "auth_source_ref"
        # convert users auth_source_ref to osx_record_guid
        User.find_each do |user|
            if user.osx_record_guid.empty? && !user.auth_source_ref.nil?
                # this is an ugly hack that makes some assumptions about the format of auth_source_ref
                match = /([\w]{8}(-[\w]{4}){3}-[\w]{12})/.match(Base64.decode64(user.auth_source_ref))
                unless match.nil?
                    user.update_attribute :osx_record_guid, match[0]
                end
            end
        end
    end
  end
  desc "Update user and group information"
  task :update_users => :environment do

  end
end
