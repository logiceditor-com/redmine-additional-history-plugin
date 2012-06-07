require 'diff'

module RedmineAdditionalHistory
  module Hooks
    ORIGINALS = Hash.new

    class ControllersJournalsEditPostHook < Redmine::Hook::ViewListener

      def controller_journals_edit_post(context={})
        journal = context[:journal]
        Mailer.deliver_issue_comment_edit(journal)
      end
    end
  end
end