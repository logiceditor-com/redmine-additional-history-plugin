require_dependency 'issue_relations_controller'

module IssueRelationsControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, AdditionalHistoryPatchBase)
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :create_without_post_changes, :create unless method_defined?(:create_without_post_changes)
      alias_method :create, :create_with_post_changes

      alias_method :destroy_without_post_changes, :destroy unless method_defined?(:destroy_without_post_changes)
      alias_method :destroy, :destroy_with_post_changes
    end

  end

  module InstanceMethods
    def create_with_post_changes
      create_without_post_changes

      post_issue_relation_comment(@relation, true, true)
      post_issue_relation_comment(@relation, false, true)
    end

    def destroy_with_post_changes
      destroy_without_post_changes

      post_issue_relation_comment(@relation, true, false)
      post_issue_relation_comment(@relation, false, false)
    end

    private

    def get_type_name(relation_type_name, is_forward)
      relation_type_forward_name = "???"
      relation_type_back_name = "???"
      if relation_type_name == "relates" then
        relation_type_forward_name = "relates with"
        relation_type_back_name = "relates with"
      elsif relation_type_name == "duplicates" then
        relation_type_forward_name = "duplicates"
        relation_type_back_name = "duplicated by"
      elsif relation_type_name == "duplicated" then
        relation_type_forward_name = "duplicated by"
        relation_type_back_name = "duplicates"
      elsif relation_type_name == "blocks" then
        relation_type_forward_name = "blocks"
        relation_type_back_name = "blocked by"
      elsif relation_type_name == "blocked" then
        relation_type_forward_name = "blocked by"
        relation_type_back_name = "blocks"
      elsif relation_type_name == "precedes" then
        relation_type_forward_name = "precedes"
        relation_type_back_name = "follows"
      elsif relation_type_name == "follows" then
        relation_type_forward_name = "follows"
        relation_type_back_name = "precedes"
      end

      if is_forward then
        return relation_type_forward_name
      else
        return relation_type_back_name
      end

    end

    def post_issue_relation_comment(relation, is_forward, is_add)
      relation_type_name = relation.relation_type.to_s
      relation_type_message = get_type_name(relation_type_name, is_forward)

      if is_add then
        message = "This ticket now "
      else
        message = "This ticket now no more "
      end
      message = message + relation_type_message + " #"
      if is_forward then
        message = message + relation.issue_to_id.to_s+": "+relation.issue_to.subject
      else
        message = message + relation.issue_from_id.to_s+": "+relation.issue_from.subject
      end

      message = AdditionalHistoryPatchBase::PREFIX + message

      n = Journal.new :notes => message
      n.user = User.current
      if is_forward then
        n.journalized = relation.issue_from
      else
        n.journalized = relation.issue_to
      end
      n.save

    end

  end

end
