module AdditionalHistoryPatchBase
  PREFIX = "[additional_history] "

  def post_comment(issue, text)
    comment = Journal.new :notes => text
    comment.user = User.current
    comment.journalized = issue
    comment.save
  end

  def humanize_hours(hours)
    hours.to_f.round(2)
  end
end