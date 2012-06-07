require_dependency 'timelog_controller'

require 'AdditionalHistoryPatchBase'

module TimelogControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, AdditionalHistoryPatchBase)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :create_without_post_changes, :create unless method_defined?(:create_without_post_changes)
      alias_method :create, :create_with_post_changes

      alias_method :update_without_post_changes, :update unless method_defined?(:update_without_post_changes)
      alias_method :update, :update_with_post_changes

      alias_method :destroy_without_post_changes, :destroy unless method_defined?(:destroy_without_post_changes)
      alias_method :destroy, :destroy_with_post_changes
    end
  end

  PREFIX = "[additional_history_plugin] "
  module InstanceMethods

    def create_with_post_changes
      create_without_post_changes

      if !@time_entry.new_record?
        post_comment(@issue, "#{PREFIX}ST added: #{humanize_hours(@time_entry.attributes['hours'])} (#{@time_entry.attributes['comments']}) (total: #{humanize_hours(@time_entry.issue.total_spent_hours)})")
      end
    end

    def update_with_post_changes
      original_hours = @time_entry.attributes['hours'];

      update_without_post_changes

      if @time_entry.errors.length == 0
        post_comment(@time_entry.issue, "#{PREFIX}ST changed: #{humanize_hours(original_hours)} -> #{humanize_hours(@time_entry.attributes['hours'])} (#{@time_entry.attributes['comments']}) (total: #{humanize_hours(@time_entry.issue.total_spent_hours)})")
      end
    end

    def destroy_with_post_changes
      destroy_without_post_changes

      @time_entries.each do |time_entry|
        post_comment(time_entry.issue, "#{PREFIX}ST removed: #{humanize_hours(time_entry.attributes['hours'])} (#{time_entry.attributes['comments']}) (total: #{humanize_hours(time_entry.issue.total_spent_hours)})")
      end
    end

  end

end
