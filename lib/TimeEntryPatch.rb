require_dependency 'time_entry'

module TimeEntryPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :validate_time_entry_without_enhance, :validate_time_entry unless method_defined?(:validate_time_entry_without_enhance)
      alias_method :validate_time_entry, :validate_time_entry_with_enhance
    end
  end

  module InstanceMethods

    def validate_time_entry_with_enhance
      validate_time_entry_without_enhance

      errors.add :comments, :blank if comments.empty?
    end

  end

end
