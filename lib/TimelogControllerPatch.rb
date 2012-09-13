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

  module InstanceMethods

    def create_with_post_changes
      create_without_post_changes

      if !@time_entry.new_record?
        st = humanize_hours(@time_entry.attributes['hours'])
        comments = @time_entry.attributes['comments']
        total_st = humanize_hours(@time_entry.issue.total_spent_hours)
        et = humanize_hours(@time_entry.issue.estimated_hours)
        post_comment(@issue, "#{AdditionalHistoryPatchBase::PREFIX}*ST added*: #{st} (#{comments}) (total: *#{total_st} / #{et}*)")
      end
    end

    def update_with_post_changes
      original_hours = @time_entry.hours;
      original_issue_id = @time_entry.issue_id;

      update_without_post_changes

      if @time_entry.errors.length == 0
        original_hours = humanize_hours(original_hours)
        comments = @time_entry.attributes['comments']

        if original_issue_id == @time_entry.issue_id
          new_hours = humanize_hours(@time_entry.attributes['hours'])
          total_st = humanize_hours(@time_entry.issue.total_spent_hours);
          et = humanize_hours(@time_entry.issue.estimated_hours)
          post_comment(@time_entry.issue, "#{AdditionalHistoryPatchBase::PREFIX}*ST changed*: #{original_hours} -> #{new_hours} (#{comments}) (total: *#{total_st} / #{et}*)")
        else
          new_hours = humanize_hours(@time_entry.attributes['hours'])
          total_st = humanize_hours(@time_entry.issue.total_spent_hours);
          et = humanize_hours(@time_entry.issue.estimated_hours)

          original_issue = Issue.find_by_id(original_issue_id)
          original_total_st = humanize_hours(original_issue.total_spent_hours);
          original_et = humanize_hours(original_issue.estimated_hours)

          message = "#{AdditionalHistoryPatchBase::PREFIX}*ST moved*: #{original_hours} ->  ##{@time_entry.issue.id} #{new_hours} (#{comments}) (total: *#{original_total_st} / #{original_et}*)"
          post_comment(original_issue, message)

          message = "#{AdditionalHistoryPatchBase::PREFIX}*ST moved*: ##{original_issue_id} #{original_hours} ->  #{new_hours} (#{comments}) (total: *#{total_st} / #{et}*)"
          post_comment(@time_entry.issue, message)
        end
      end
    end

    def destroy_with_post_changes
      destroy_without_post_changes

      @time_entries.each do |time_entry|
        st = humanize_hours(time_entry.attributes['hours'])
        comments = time_entry.attributes['comments']
        total_st = humanize_hours(time_entry.issue.total_spent_hours)
        et = humanize_hours(time_entry.issue.estimated_hours)
        post_comment(time_entry.issue, "#{AdditionalHistoryPatchBase::PREFIX}*ST removed*: #{st} (#{comments}) (total: *#{total_st} / #{et}*)")
      end
    end

  end

end
