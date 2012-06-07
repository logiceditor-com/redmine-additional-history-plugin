require_dependency 'issues_controller'

module MailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :attachments_added_without_enhance, :attachments_added unless method_defined?(:attachments_added_without_enhance)
      alias_method :attachments_added, :attachments_added_with_enhance
    end
  end

  module InstanceMethods

    def attachments_added_with_enhance(attachments)
      add_result = attachments_added_without_enhance(attachments)
      add_result.each do |action_mailer|
        attachments.each do |attachment|
          filepath = RAILS_ROOT + "/files/" + attachment.disk_filename
          action_mailer.attachment :content_type => attachment.content_type,
                                   :body => File.read(filepath),
                                   :filename => attachment.filename
        end

        is_in_issue = attachments.first.container.class.name == 'Issue'
        if is_in_issue
          issue = attachments.first.container
          added_to_url = url_for(:controller => 'issues', :action => 'show', :id => 1)
          added_to = "#{l(:label_issue)}: #{issue.subject}"
          subject "[#{issue.project.name} - New #{issue.tracker.name}] #{l(:label_attachment_new)} (#{issue.subject})"
          body :attachments => attachments,
               :added_to => added_to,
               :added_to_url => added_to_url

          recipients issue.recipients

        end

        break
      end

      add_result
    end

  end
end
