require 'redmine'

require 'dispatcher'
require 'TimelogControllerPatch'

Dispatcher.to_prepare :redmine_additional_history do
  require_dependency 'timelog_controller'
  TimelogController.send(:include, TimelogControllerPatch)
end

Redmine::Plugin.register :redmine_additional_history do
  name 'Redmine Additional History plugin'
  author 'Alexey Romanov'
  description 'Add comments to ticket on some actions'
  version '0.0.1'
  url 'http://logiceditor.com'
  author_url 'http://logiceditor.com'
end
