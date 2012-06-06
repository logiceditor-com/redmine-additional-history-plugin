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
                                   :body => File.read(filepath)
        end
      end

      add_result
    end

  end

end
