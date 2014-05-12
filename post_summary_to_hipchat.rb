require 'open-uri'
require 'date'
require 'hipchat'
require 'json/pure'

SEPARATOR = ":"
MINUTEDOCK_URL = "https://minutedock.com/api/v1/"
yesterday = (Date.today - 1).strftime('%d%b%Y')

api_keys = []
IO.foreach('./../api_keys.txt') { |key| api_keys << key.chomp.split(":") }


class Minutedock

  def get_collective_data(url)
    result = open(url).read
    json = JSON.parser.new(result)
    hash = json.parse()
  end

   def get_item(url = nil, hash, id_name)
    if url
      item = get_item_by_id(hash, url, id_name)
    else
      item = get_item_by_name(hash, id_name)
    end
  end

  def add_time(project, time, unique_hash, project_name)
    project.length.times { |i|
      if project_name.include?(project[i])
        unique_hash.map { |hash| hash[:time] += time[i].to_i if hash.has_value?(project[i])}
      else
        unique_hash << Hash[project: project[i], time: time[i].to_i] unless project[i].empty? || time[i].empty?
        project_name << project[i]
      end
    }
  end
  
  private

  def get_name_by_id(hash, id)
    hash.reject! { |data| return data["name"] if data["id"] == id }
  end

  def get_id_from_entrydata(entrydata, id_name)
    id = entrydata[id_name]
  end

  def get_item_by_id(hash, url, id_name)
    hash.map { |data|
      id = get_id_from_entrydata(data, id_name)
      info = get_collective_data(url)
      if id.class == Array
        item = id.map{ |i| get_name_by_id(info, i)}.join(",")
      else
        item = get_name_by_id(info, id)
      end
    }

  end

  def get_item_by_name(hash, id_name)
    hash.map { |data|
      item = data[id_name]
    }
  end

end

class DailyTimeTextPresenter

  def present(item, category)
    item = item.map{ |item| change_second_to_hour(item).to_s } if category == "Time"
    summary = make_statement(item, category)
  end


  def put_together(contact, project, task, time, desciption)
    length = contact.length

    summaries = []
    length.times{ |i|
      summaries << contact[i] + "  " + project[i] + "  " + task[i] + "  " + time[i] + "  " + desciption[i]
    }
    return summaries
  end

=begin
  def put_together(array, *args)
    array << args
  end
=end
  def convert_time(interval = 2.0, time)
      time = change_second_to_hour(time)
      time = round_to_nearest(interval, time)
  end

  private

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

project_data = []
time_data = []
project_name = []
hash = []
result = []

user = Minutedock.new
presenter = DailyTimeTextPresenter.new

api_keys.map{ |key|

  url_entry = "#{MINUTEDOCK_URL}entries.json?api_key=#{key[1]}&from=#{yesterday}&to=#{yesterday}"

  url_project = "#{MINUTEDOCK_URL}projects.json?api_key=#{key[1]}"
  
  
  entry_data = user.get_collective_data(url_entry)

  project_data = user.get_item(url_project, entry_data, "project_id").join(",").split(",")
  time_data = user.get_item(entry_data, "duration").join(",").split(",")

  user.add_time(project_data, time_data, hash, project_name)

}

hash.map{ |hash|
  print "##{hash[:project]} #{presenter.convert_time(hash[:time])},"
}






