require 'open-uri'
require 'date'
require 'hipchat'
require 'json/pure'

SEPARATOR = ":"
MINUTEDOCK_URL = "https://minutedock.com/api/v1/"
yesterday = (Date.today - 1).strftime('%d%b%Y')
url_entry = "#{MINUTEDOCK_URL}entries.json?users=18590&from=#{yesterday}&to=#{yesterday}"
url_contact = "#{MINUTEDOCK_URL}contacts.json"
url_project = "#{MINUTEDOCK_URL}projects.json"
url_task = "#{MINUTEDOCK_URL}tasks.json"

#Minutedock class collects infromation from Minutedock app
class Minutedock

	attr_accessor :hash, :url, :id_name, :category

	def initialize(hash = nil, url, id_name, category)
		@hash = hash
		@url = url
		@id_name = id_name
		@category = category
	end

	def get_collective_data(url)
		user = "ayumi.highroof@gmail.com"
		pass = "minute4649"
		result = open(url, :http_basic_authentication => [user, pass]).read
		json = JSON.parser.new(result)
		hash = json.parse()
	end

	def get_name_by_id(hash, id)
		hash.reject! { |data| return data["name"] if data["id"] == id }
	end


	def get_id_from_entrydata(entrydata, id_name)
		id = entrydata[id_name]
	end


	def get_item_by_url(hash, url, id_name)
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


	def get_item(hash, id_name)
		hash.map { |data|
			item = data[id_name]
		}
	end

	def change_second_to_hour(times)
		times.map { |time|
			time = time / 60 / 60.0
			time = "#{time.round(1)}h"
		}
	end

	def make_statement(results, category)
		results.map { |result|
			if result
				result = category + SEPARATOR + result
			else
				result = "No " + category
			end
		}
	end

=begin
	def get_summary(hash)
		hash.map { |data|
			id = get_id_from_entrydata(data, id)
			info = get_collective_data(url)
			
			
		}

	end
=end
	def put_together(contact, project, task, time, desciption)
			length = contact.length
			summaries = []
			length.times{ |i|
			return summaries << contact[i] + " " + project[i] + " " + task[i] + " " + time[i] + " " + desciption[i]
			}
	end

end

client = HipChat::Client.new("6ece3454ac2e42e41faa3f384d5957")
summary = Minutedock.new(url_contact, "contact_id", "Contact")
data = summary.get_collective_data(url_entry)


contact = summary.get_item_by_url(data, url_contact, "contact_id")
project = summary.get_item_by_url(data, url_project, "project_id")
task = summary.get_item_by_url(data, url_task, "task_ids")
time = summary.get_item(data, "duration")
desc = summary.get_item(data, "description")

time = summary.change_second_to_hour(time)

contact = summary.make_statement(contact, "Contact")
project = summary.make_statement(project, "Project")
task = summary.make_statement(task, "Task")
time = summary.make_statement(time, "Time")
desc = summary.make_statement(desc, "Description")

puts summaries = summary.put_together(contact, project, task, time, desc)
=begin
summaries.map { |summary|
	client["test"].send('Ayumi Udaka', summary)
}
=end
