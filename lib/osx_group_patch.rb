require_dependency 'group'

module OsxGroupPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      belongs_to :auth_source
      
      validates_each :lastname do |model, attr, value|
        if model.auth_source
          # check to see if auth_source recognizes the group
          ref = model.auth_source.reference_for_group_name(value)
          if ref
            model.auth_source_ref = ref
          else
              model.errors.add(attr, l(:group_not_found))
          end
        else
          # fix auth_source_ref
          model.auth_source_ref = nil
        end
      end
      
      after_save :update_external_users
    end
  end
  
  module ClassMethods
    # nothing for now
  end
  
  module InstanceMethods
    
    def update_external_users(user_list = nil)
      return unless auth_source
      unless user_list
        user_list = auth_source.users
      end
      user_list.each do |u|
        if auth_source.user_in_group(u,self)
          # add if missing
          unless users.include?(u)
            users << u
          end
        else
          #remove if present
          if users.include?(u)
            users.delete(u)
          end
        end
      end
    end
    
  end
  
end
