require_dependency 'issues_controller'

require 'AdditionalHistoryPatchBase'

module WatchersControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, AdditionalHistoryPatchBase)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :create_without_post_changes, :create unless method_defined?(:create_without_post_changes)
      alias_method :create, :create_with_post_changes

      #alias_method :update_without_post_changes, :update unless method_defined?(:update_without_post_changes)
      #alias_method :update, :update_with_post_changes

      alias_method :destroy_without_post_changes, :destroy unless method_defined?(:destroy_without_post_changes)
      alias_method :destroy, :destroy_with_post_changes
    end
  end

  module InstanceMethods

    def create_with_post_changes
      create_without_post_changes

      if params['object_type'] == "issue"
        issue = Issue.find(params[:object_id])
        if params[:watcher].is_a?(Hash) && request.post?
          user_names = []
          user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
          user_ids.each do |user_id|
            user = User.find(user_id)
            user_names << user.name
          end
          user_names = user_names.join(", ")

          post_comment(issue, "#{user_names} was added to watchers")
        end
      end
    end

    #def update_with_post_changes
      #update_without_post_changes
    #end

    def destroy_with_post_changes
      destroy_without_post_changes

      if params['object_type'] == "issue"
        user = User.find(params[:user_id])
        issue = Issue.find(params[:object_id])
        post_comment(issue, "Watcher #{user.name} was removed")
      end
    end

  end

end
