module AdditionalHistoryPatchBase
  PREFIX = "_[additional_history]_ "

  def post_comment(issue, text)
    comment = Journal.new :notes => text
    comment.user = User.current
    comment.journalized = issue
    comment.save
  end

  def humanize_hours(hours)
    hours = hours.to_f
    h = hours.floor
    m = ((hours - h) * 60).round

    res = ""
    if(h > 0)
      res += "#{h}h"
    end
    if(m > 0)
      res += "#{m}m"
    end

    if res.empty?
      res = "none"
    end

    res
  end

  def parse_hours(hours)
    if hours.index(',') != nil
      hours[","] = "."
    end

    matches = hours.match(/([\d\.]+)\s*(([hm]?)\s*((\d+)\s*(m?))?)?/)

    if matches[2] == nil
      hours = matches[1].to_f.round(2)
    elsif matches[2] == "m"
      hours = (matches[1].to_f / 60).round(2)
    elsif matches[2] == "h"
      hours = matches[1].to_f.round(2)
    else
      hours = (matches[1].to_f + matches[5].to_f / 60).round(2)
    end

    return hours
  end
end