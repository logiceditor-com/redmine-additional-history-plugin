require_dependency 'issues_controller'

require 'AdditionalHistoryPatchBase'

module IssuesControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, AdditionalHistoryPatchBase)
    base.send(:include, InstanceMethods)

    base.class_eval do
      #alias_method :create_without_post_st_changes, :create unless method_defined?(:create_without_post_st_changes)
      #alias_method :create, :create_with_post_st_changes

      alias_method :update_without_post_st_changes, :update unless method_defined?(:update_without_post_st_changes)
      alias_method :update, :update_with_post_st_changes

      #alias_method :destroy_without_post_st_changes, :destroy unless method_defined?(:destroy_without_post_st_changes)
      #alias_method :destroy, :destroy_with_post_st_changes
    end
  end

  module InstanceMethods

    #def create_with_post_st_changes
    #  create_without_post_st_changes
    #end

    def update_with_post_st_changes
      if params['time_entry']['hours'].to_i > 0 && params['time_entry']['activity_id'].to_i > 0
        params['notes'] = "ST added: #{params['time_entry']['hours']} (#{params['time_entry']['comments']})\n\n#{params['notes']}"
      end
      
      update_without_post_st_changes
    end

    #def destroy_with_post_st_changes
    #  destroy_without_post_st_changes
    #end

  end

end
