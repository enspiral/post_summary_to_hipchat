class DailyTimeTextPresenter

  def present(item, category)
    item = item.map{ |item| convert_time(item).to_s } if category == "Time"
    summary = make_statement(item, category)
  end

  def make_statement_per_entry(contact, project, task, time, desciption)
    length = contact.length

    summaries = []
    length.times{ |i|
      summaries << contact[i] + "  " + project[i] + "  " + task[i] + "  " + time[i] + "  " + desciption[i]
    }
    return summaries
  end

  def format_project_time(hash)
    result = []
    hash.map{ |hash| 
      time = convert_time(hash[:time])
      result << "##{hash[:project]} #{time}"
    }
    result
  end

  def format_personal_time(hash)
    result = []
    hash.map{ |hash|
      billiable = convert_time(hash[:billiable])
      unbilliable = convert_time(hash[:unbilliable])
      result << "#{hash[:name]} (#{billiable} / #{unbilliable})"
    }
    result
  end

  def put_together(*args)
    array = []
    array << args
    array.join(" ")
  end

  private

  def convert_time(interval = 2.0, time)
      time = change_second_to_hour(time)
      time = round_to_nearest(interval, time)
  end

  def get_value_by_key(hash, *key)
    array = []
    array << hash.values
  end

  def round_to_nearest(interval, time)
    time = (time * interval).round / interval
  end

  def change_second_to_hour(time)
    time = (time / 60 / 60.0).round(1)
  end

  def make_statement(results, category)
    results.map { |result|

      if result.nil? || result.empty?
        result = "No " + category
      else
        result = category + SEPARATOR + result
      end
    }
  end
  
end
