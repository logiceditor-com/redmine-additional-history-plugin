module AdditionalHistoryPatchBase
  def post_comment(issue, text)
    comment = Journal.new :notes => text
    comment.user = User.current
    comment.journalized = issue
    comment.save
  end
end