require_dependency 'mailer'
require 'cgi'

module MailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :attachments_added_without_enhance, :attachments_added unless method_defined?(:attachments_added_without_enhance)
      alias_method :attachments_added, :attachments_added_with_enhance

      if Rails::VERSION::MAJOR >= 3
        alias_method :mail_without_enhance, :mail unless method_defined?(:mail_without_enhance)
        alias_method :mail, :mail_with_enhance

        alias_method :issue_edit_without_enhance, :issue_edit unless method_defined?(:issue_edit_without_enhance)
        alias_method :issue_edit, :issue_edit_with_enhance

        alias_method :issue_add_without_enhance, :issue_add unless method_defined?(:issue_add_without_enhance)
        alias_method :issue_add, :issue_add_with_enhance

        plugin_path = File.join(Rails.root.to_s,'plugins') + "/" + File.dirname(__FILE__).gsub(File.join(Rails.root.to_s,'plugins'),'').split('/')[1]
        view_path = plugin_path + "/app/views"
        self.view_paths.unshift(view_path)
      else
        alias_method :render_multipart_without_enhance, :render_multipart unless method_defined?(:render_multipart_without_enhance)
        alias_method :render_multipart, :render_multipart_with_enhance

        instance_variable_get("@inheritable_attributes")[:view_paths].unshift(RAILS_ROOT + "/vendor/plugins/redmine-additional-history-plugin/app/views")
      end
    end
  end

  class PostDiff
    include ERB::Util
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    attr_reader :diff, :words

    def initialize(content_to, content_from)
      @words = content_to.to_s.gsub("\r", "").split(/(\n+)/)
      @words = @words.select {|word| word != ' '}
      words_from = content_from.to_s.gsub("\r", "").split(/(\n+)/)
      words_from = words_from.select {|word| word != ' '}
      @diff = words_from.diff @words
    end

    def to_text
      words = self.words.collect{|word| h(word)}
      lines = []
      diff.diffs.each do |diff|
        diff.each do |change|
          sign = change[0]
          pos = change[1]
          text = change[2]
          text.strip!
          if !text.empty?
            lines << CGI.escapeHTML(sign + " " + text)
          end
        end
        lines << "<br />"
      end
      lines.join('<br />').html_safe
    end
  end

  module InstanceMethods
    @@attachments = nil

    def attachments_added_with_enhance(attachments)
      @@attachments = attachments
      add_result = attachments_added_without_enhance(attachments)

      #add_result.each do |action_mailer|
      #  attachments.each do |attachment|
      #    filepath = RAILS_ROOT + "/files/" + attachment.disk_filename
      #    action_mailer.attachment :content_type => attachment.content_type,
      #                             :body => File.read(filepath),
      #                             :filename => attachment.filename
      #  end
      #
      #  is_in_issue = attachments.first.container.class.name == 'Issue'
      #  if is_in_issue
      #    issue = attachments.first.container
      #    added_to_url = url_for(:controller => 'issues', :action => 'show', :id => 1)
      #    added_to = "#{l(:label_issue)}: #{issue.subject}"
      #    subject "[#{issue.project.name} - New #{issue.tracker.name}] #{l(:label_attachment_new)} (#{issue.subject})"
      #    body :attachments => attachments,
      #         :added_to => added_to,
      #         :added_to_url => added_to_url
      #
      #    recipients issue.recipients
      #
      #  end
      #
      #  break
      #end
      #
      #add_result.pop # hack for gmail can see attaches properly
      #
      add_result
    end

    def issue_comment_edit(journal)
      original_text = RedmineAdditionalHistory::Hooks::ORIGINALS[journal.id]
      new_text = journal.notes
      diff = PostDiff.new(new_text, original_text)
      diff_text = diff.to_text

      issue = journal.journalized.reload
      redmine_headers 'Project' => issue.project.identifier,
                      'Issue-Id' => issue.id,
                      'Issue-Author' => issue.author.login
      redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
      message_id journal
      references issue
      @author = User.current
      recipients issue.recipients
      # Watchers in cc
      cc(issue.watcher_recipients - @recipients)
      s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
      s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
      s << issue.subject
      subject s
      body :issue => issue,
           :journal => journal,
           :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}"),
           :diff_text => diff_text,
           :author => User.current

      render_multipart('issue_comment_edit', body)
    end

    def perform_attach(attachment_item)
      if Rails::VERSION::MAJOR >= 3
        filepath = attachment_item.storage_path + "/" + attachment_item.disk_filename
        # content = File.read(filepath) # not work on windows
        content = open(filepath, "rb") {|io| io.read }
        attachments[attachment_item.filename] = {:mime_type => attachment_item.content_type,
                                                 :content => content}
      else
        filepath = RAILS_ROOT + "/files/" + attachment_item.disk_filename
        attachment :content_type => attachment_item.content_type,
                   :body => File.read(filepath),
                   :filename => attachment_item.filename
      end
    end

    def perform_attaches(attachments)
      if attachments
        attachments.each do |attachment_item|
          perform_attach(attachment_item)
        end
      end
    end

    def render_multipart_with_enhance(method_name, body)
      if method_name == 'issue_edit' || method_name == 'issue_comment_edit'
        journal = body[:journal]
        details = journal.details

        details.each do |detail|
          if detail.property == 'attachment'
            if detail.value != nil
              attachment_item = Attachment::find(detail.prop_key)
              perform_attach(attachment_item)
            end
          end
        end
      elsif method_name == 'issue_add'
        issue = body[:issue]
        attachments = Attachment.find_all_by_container_type_and_container_id('Issue', issue.id)
        perform_attaches(attachments);
      elsif method_name == 'attachments_added'
        attachments = body[:attachments]
        perform_attaches(attachments);
      elsif method_name == 'document_added'
        attachments = body[:document].attachments
        perform_attaches(attachments);
      end

      render_multipart_without_enhance(method_name, body)
    end

    def mail_with_enhance(headers={})
      #if method_name == 'issue_edit' || method_name == 'issue_comment_edit'
      #  journal = body[:journal]
      #  details = journal.details
      #
      #  details.each do |detail|
      #    if detail.property == 'attachment'
      #      if detail.value != nil
      #        attachment_item = Attachment::find(detail.prop_key)
      #        perform_attach(attachment_item)
      #      end
      #    end
      #  end
      #elsif method_name == 'issue_add'
      #  issue = body[:issue]
      #  attachments = Attachment.find_all_by_container_type_and_container_id('Issue', issue.id)
      #  perform_attaches(attachments)
      #elsif method_name == 'attachments_added'
      #  attachments = body[:attachments]
      #  perform_attaches(attachments)
      #elsif method_name == 'document_added'
      #  attachments = body[:document].attachments
      #  perform_attaches(attachments)
      #end

      if @@attachments != nil
        perform_attaches(@@attachments)
      end

      res = mail_without_enhance(headers)

      res
    end

    def issue_edit_with_enhance(journal)
      res = issue_edit_without_enhance(journal)
      @@attachments = nil
      res
    end

    def issue_add_with_enhance(journal)
      res = issue_add_without_enhance(journal)
      @@attachments = nil
      res
    end

  end
end
