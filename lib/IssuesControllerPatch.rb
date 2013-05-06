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

    def update_with_post_st_changes
      if Rails::VERSION::MAJOR >= 3
        notes_obj = params['issue']
      else
        notes_obj = params
      end

      original_notes = notes_obj['notes']

      time_entry = params['time_entry']
      if time_entry
        if time_entry['hours'].to_f > 0 && time_entry['activity_id'].to_i > 0 && !time_entry['comments'].empty?
          st = parse_hours(params['time_entry']['hours'])
          comments = params['time_entry']['comments']
          total_st = humanize_hours(@issue.total_spent_hours + st)
          st = humanize_hours(st)
          et = humanize_hours(params['issue']['estimated_hours'])
          notes_obj['notes'] = "#{AdditionalHistoryPatchBase::PREFIX}*ST added*: #{st} (#{comments}) (total: *#{total_st} / #{et}*)\n\n#{notes_obj['notes']}"
        end
      end

      update_original_and_enhanced(original_notes)
    end

    def update_original_and_enhanced(original_notes)
      return unless update_issue_from_params
      @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
      saved = false
      begin
        saved = @issue.save_issue_with_child_records(params, @time_entry)
      rescue ActiveRecord::StaleObjectError
        @conflict = true
        if params[:last_journal_id]
          if params[:last_journal_id].present?
            last_journal_id = params[:last_journal_id].to_i
            @conflict_journals = @issue.journals.all(:conditions => ["#{Journal.table_name}.id > ?", last_journal_id])
          else
            @conflict_journals = @issue.journals.all
          end
        end
      end

      if saved
        render_attachment_warning_if_needed(@issue)
        flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

        respond_to do |format|
          format.html { redirect_back_or_default({:action => 'show', :id => @issue}) }
          format.api  { head :ok }
        end
      else
        if Rails::VERSION::MAJOR >= 3            # enhance code
          params.issue['notes'] = original_notes # enhance code
        else                                     # enhance code
          params['notes'] = original_notes       # enhance code
        end                                      # enhance code
        @notes = original_notes                  # enhance code

        respond_to do |format|
          format.html { render :action => 'edit' }
          format.api  { render_validation_errors(@issue) }
        end
      end
    end

  end

end
