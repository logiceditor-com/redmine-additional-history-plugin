require_dependency 'mailer'

module MailerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :attachments_added_without_enhance, :attachments_added unless method_defined?(:attachments_added_without_enhance)
      alias_method :attachments_added, :attachments_added_with_enhance
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
            lines << sign + " " + text
          end
        end
        lines << "<br />"
      end
      lines.join('<br />').html_safe
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
      @author = journal.user
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
           :diff_text => diff_text

      render_multipart('issue_edit', body)
    end
  end
end
