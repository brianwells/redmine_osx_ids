namespace :redmine_osx_ids do
  desc "Migrate Identity Services data to Open Directory data"
  task :migrate_data => :environment do
    if AuthSource.column_names.include? "osx_identity_authority"
        # convert auth_sources osx_identity_authority to osx_node_name
        AuthSourceOsx.find_each do |auth_source|
            if auth_source.osx_node_name.blank?
                if auth_source.osx_identity_authority == "default" || auth_source.osx_identity_authority == "managed"
                    auth_source.update_column :osx_node_name, "/Search"
                    auth_source.update_column :host, "/Search"
                end
                if auth_source.osx_identity_authority == "local"
                    auth_source.update_column :osx_node_name, "/Local/Default"
                    auth_source.update_column :host, "/Local/Default"
                end
            end
        end
    end
    if Principal.column_names.include? "auth_source_ref"
        # convert users/groups auth_source_ref to osx_record_guid
        Principal.find_each do |principal|
            if principal.osx_record_guid.blank? && !principal.auth_source_ref.nil?
                # this is an ugly hack that makes some assumptions about the format of auth_source_ref
                match = /([\w]{8}(-[\w]{4}){3}-[\w]{12})/.match(Base64.decode64(principal.auth_source_ref))
                unless match.nil?
                    principal.update_column :osx_record_guid, match[0]
                end
            end
        end
    end
  end
  desc "Update user and group information"
  task :update_users => :environment do
    # for each osx_auth_source
    AuthSourceOsx.find_each do |auth_source|
      # check node
      if OpenDirectory.nodeDetails(auth_source.osx_node_name).nil?
        puts "ERROR: Node \"#{auth_source.osx_node_name}\" for authentication mode \"#{auth_source.name}\" not found."
      else
        # check users
        auth_source.users.each do |user|
          if OpenDirectory.recordName(user.osx_record_guid,auth_source.osx_node_name) != user.login
            guid = OpenDirectory.userGUID(user.login,auth_source.osx_node_name)
            unless guid
              puts "ERROR: User \"#{user.login}\" not found in node \"#{auth_source.osx_node_name}\"."
              # could delete the user, but that might be disastrous
            else
              if guid != user.osx_record_guid
                puts "WARNING: Updating user \"#{user.login}\" with GUID \"#{guid}\"."
                user.update_column :osx_record_guid, guid
              end
            end
          end
        end
        # check groups
        groups = auth_source.groups.select do |group|
          result = true
          if OpenDirectory.recordName(group.osx_record_guid,auth_source.osx_node_name) != group.name
            guid = OpenDirectory.groupGUID(group.name,auth_source.osx_node_name)
            unless guid
              puts "ERROR: Group \"#{group.name}\" not found in node \"#{auth_source.osx_node_name}\"."
              # could delete the group, but that might be disastrous
              result = false
            else
              if guid != group.osx_record_guid
                puts "WARNING: Updating group \"#{group.name}\" with GUID \"#{guid}\"."
                group.update_column :osx_record_guid, guid
              end
            end
          end
          result
        end
        # update group membership
        groups.each do |group|
          guids = OpenDirectory.usersInGroupByGUID(group.osx_record_guid,auth_source.osx_node_name)
          # add missing users
          guids.reject{ |g| User.where(:osx_record_guid => g, :auth_source_id => auth_source.id).exists? }.each do |guid|
            # get user info
            attrs = OpenDirectory.userAttributes(guid,["dsAttrTypeStandard:FirstName","dsAttrTypeStandard:LastName","dsAttrTypeStandard:EMailAddress","dsAttrTypeStandard:RecordName"],auth_source.osx_node_name)
            rn = attrs["dsAttrTypeStandard:RecordName"] ? attrs["dsAttrTypeStandard:RecordName"][0].downcase : nil
            fn = attrs["dsAttrTypeStandard:FirstName"] ? attrs["dsAttrTypeStandard:FirstName"][0] : nil
            ln = attrs["dsAttrTypeStandard:LastName"] ? attrs["dsAttrTypeStandard:LastName"][0] : nil
            em = attrs["dsAttrTypeStandard:EMailAddress"] ? attrs["dsAttrTypeStandard:EMailAddress"][0].downcase : nil
            # user has record name, first & last name, and email address?
            if rn && fn && ln && em
              puts "INFO: Adding user \"#{rn}\" (guid: #{guid})"
              user = User.new(:osx_record_guid => guid,
                              :auth_source_id => auth_source.id,
                              :firstname => fn,
                              :lastname => ln,
                              :mail => em)
              user.language = Setting.default_language
              user.login = rn
              unless user.save
                # unable to add user
                puts "ERROR: Unable to add user \"#{rn}\". #{user.errors.full_messages.join("; ")}"
                guids.delete(guid)
              end
            else
              puts "WARNING: Skipping user with incomplete information (guid: #{guid})"
              puts "         RecordName: #{rn}"
              puts "         FirstName: #{fn}"
              puts "         LastName: #{ln}"
              puts "         EMailAddress: #{em}"
              guids.delete(guid)
            end
          end
          # update users for group
          current_users = group.users.pluck(:osx_record_guid)
          (current_users - guids).each do |guid|
            unless OpenDirectory.groupContainsUser(group.osx_record_guid,guid,auth_source.osx_node_name)
              user = User.find_by_osx_record_guid(guid)
              puts "INFO: Removing user \"#{user.login}\" from group \"#{group.name}\""
              group.users.delete(user)
            end
          end
          (guids - current_users).each do |guid|
            user = User.find_by_osx_record_guid(guid)
            puts "INFO: Adding user \"#{user.login}\" to group \"#{group.name}\""
            group.users << user
          end
        end
      end
    end
  end
end
