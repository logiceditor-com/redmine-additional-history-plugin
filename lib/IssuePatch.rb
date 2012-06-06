require_dependency 'issue'

module IssuePatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :save_attachments_without_enhance, :save_attachments unless method_defined?(:save_attachments_without_enhance)
      alias_method :save_attachments, :save_attachments_with_enhance
    end
  end

  module InstanceMethods

    def save_attachments_with_enhance(attachments, author=User.current)
      attach_result = save_attachments_without_enhance(attachments, author)

      attach_result[:files].each do |file|
        file.container = self
      end
      Mailer.deliver_attachments_added(attach_result[:files])
    end

  end

end
