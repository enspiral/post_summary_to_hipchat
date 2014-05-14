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

  def separate_bill_unbill_time(entrydata, category_data, id_name, result, name)
    unbilliable = 0
    billiable = 0

    entrydata.map{|hash|
      id = get_id_from_entrydata(hash, id_name)
      time = hash["duration"].to_i
      rate =  get_field_by_id(category_data, id, "default_rate_dollars").to_i

      if rate <= 0 || rate.nil?
        unbilliable += time
      else
        billiable += time
      end
    }
    result << Hash[name: name, billiable: billiable, unbilliable: unbilliable] 
  end

  private

  def get_id_from_entrydata(entrydata, id_name)
    id = entrydata[id_name]
  end


  def get_field_by_id(hash, id, field_name = "name")
    hash.reject! { |data| return data[field_name] if data["id"] == id }
  end

  def get_item_by_id(hash, url, id_name)
    hash.map { |data|
      id = get_id_from_entrydata(data, id_name)
      info = get_collective_data(url)
      if id.class == Array
        item = id.map{ |i| get_field_by_id(info, i)}.join(",")
      else
        item = get_field_by_id(info, id)
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

  def convert_time(interval = 2.0, time)
      time = change_second_to_hour(time)
      time = round_to_nearest(interval, time)
  end

  private

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

project_name = []
project_time = []
personal_time = []

user = Minutedock.new
presenter = DailyTimeTextPresenter.new
client = HipChat::Client.new("6ece3454ac2e42e41faa3f384d5957")

api_keys.map{ |key|

  url_entry = "#{MINUTEDOCK_URL}entries.json?api_key=#{key[1]}&from=#{yesterday}&to=#{yesterday}"
  url_project = "#{MINUTEDOCK_URL}projects.json?api_key=#{key[1]}"
  
  entry_data = user.get_collective_data(url_entry)
  project_data = user.get_collective_data(url_project)
  
  user.separate_bill_unbill_time(entry_data, project_data, "project_id", personal_time, key[0])
  
  project_item = user.get_item(url_project, entry_data, "project_id").join(",").split(",")
  time_item = user.get_item(entry_data, "duration").join(",").split(",")
  user.add_time(project_item, time_item, project_time, project_name)
}

project =  presenter.format_project_time(project_time)
personal = presenter.format_personal_time(personal_time)

result_string = presenter.put_together("Yesterday, Craftworks spent time on (in person hours):", project, " ", "Each person spent (billable/unbillable): ", personal)

client["test"].send('Minutedock', result_string)

