require_dependency 'journals_controller'

require 'AdditionalHistoryPatchBase'

module JournalsControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, AdditionalHistoryPatchBase)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :edit_without_enhance, :edit unless method_defined?(:edit_without_enhance)
      alias_method :edit, :edit_with_enhance
    end
  end

  module InstanceMethods

    def edit_with_enhance
      edit_without_enhance

      if !request.post?
        RedmineAdditionalHistory::Hooks::ORIGINALS[@journal.id] = @journal.notes
      end
    end

  end

end
