require 'redmine'

require 'dispatcher'
require 'TimelogControllerPatch'
require 'IssuesControllerPatch'
require 'WatchersControllerPatch'
require 'MailerPatch'
require 'IssuePatch'
require 'JournalsControllerPatch'

Dispatcher.to_prepare :redmine_additional_history do
  require_dependency 'timelog_controller'
  TimelogController.send(:include, TimelogControllerPatch)

  require_dependency 'issues_controller'
  IssuesController.send(:include, IssuesControllerPatch)

  require_dependency 'watchers_controller'
  WatchersController.send(:include, WatchersControllerPatch)

  require_dependency 'mailer'
  Mailer.send(:include, MailerPatch)

  require_dependency 'issue'
  Issue.send(:include, IssuePatch)

  require_dependency 'journals_controller'
  JournalsController.send(:include, JournalsControllerPatch)
end

Redmine::Plugin.register :redmine_additional_history do
  name 'Redmine Additional History plugin'
  author 'Alexey Romanov'
  description 'Add comments to ticket on some actions'
  version '0.0.1'
  url 'http://logiceditor.com'
  author_url 'http://logiceditor.com'
end

require "hooks/ControllersJournalsEditPostHook"