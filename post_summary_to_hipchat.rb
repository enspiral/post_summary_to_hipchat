require 'open-uri'
require 'date'
require 'hipchat'
require 'json/pure'

SEPARATOR = ":"
MINUTEDOCK_URL = "https://minutedock.com/api/v1/"
yesterday = (Date.today - 1).strftime('%d%b%Y')

api_keys = []
IO.foreach('./../api_keys.txt') { |key| api_keys << key.chomp }

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
    item = change_second_to_hour(item) if category == "Time"
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

  private

  def change_second_to_hour(times)
    times.map { |time|
      time = time / 60 / 60.0
      time = "#{time.round(1)}h"
    }
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



api_keys.map{ |key|

  url_entry = "#{MINUTEDOCK_URL}entries.json?api_key=#{key}&from=#{yesterday}&to=#{yesterday}"

  url_contact = "#{MINUTEDOCK_URL}contacts.json?api_key=#{key}"
  url_project = "#{MINUTEDOCK_URL}projects.json?api_key=#{key}"
  url_task = "#{MINUTEDOCK_URL}tasks.json?api_key=#{key}"
  user = Minutedock.new

  presenter = DailyTimeTextPresenter.new

  entry_data = user.get_collective_data(url_entry)
  contact_data = user.get_item(url_contact, entry_data, "contact_id")
  project_data = user.get_item(url_project, entry_data, "project_id")
  task_data = user.get_item(url_task, entry_data, "task_ids")
  time_data = user.get_item(entry_data, "duration")
  desc_data = user.get_item(entry_data, "description")


  contact = presenter.present(contact_data, "Contact")
  project = presenter.present(project_data, "Project")
  task = presenter.present(task_data, "Task")
  time = presenter.present(time_data, "Time")
  desc =  presenter.present(desc_data, "Description")

  puts summaries = presenter.put_together(contact, project, task, time, desc)

  client = HipChat::Client.new("6ece3454ac2e42e41faa3f384d5957")
  #client["BotLab"].send('Minutedock', "s time summary of yesterday")
  summaries.map { |summary|
    client["BotLab"].send('Minutedock', summary)
  }

}