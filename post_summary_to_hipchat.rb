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
user = "ayumi.highroof@gmail.com"
pass = "minute4649"

class Minutedock

	attr_reader :hash, :url, :id_name, :category, :user, :pass

	def initialize(args)
		@hash = args[:hash]
		@url = args[:url]
		@id_name = args[:id_name]
		@category = args[:category]
		@user = args[:user]
		@pass = args[:pass]
	end


	def get_collective_data(url, user, pass)
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
			info = get_collective_data(url, user, pass)

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
			if result.nil? || result.empty?
				result = "No " + category
			else
				result = category + SEPARATOR + result
			end
		}
	end

	def get_summary
		if url
			item = get_item_by_url(hash, url, id_name)
		else
			item = get_item(hash, id_name)
			item = change_second_to_hour(item) if id_name == "duration"
		end

		summary = make_statement(item, category)
	end

	def self.put_together(contact, project, task, time, desciption)
		length = contact.length

		summaries = []
		length.times{ |i|
			summaries << contact[i] + "  " + project[i] + "  " + task[i] + "  " + time[i] + "  " + desciption[i]
		}
		return summaries
	end


end

entry_data = Minutedock.new(:url => url_entry).get_collective_data(url_entry, user, pass)

contact = Minutedock.new(:hash => entry_data, :url => url_contact, :id_name => "contact_id", :category => "Contact", :user => user, :pass => pass).get_summary
project = Minutedock.new(:hash => entry_data, :url => url_project, :id_name => "project_id", :category => "Project", :user => user, :pass => pass).get_summary
task = Minutedock.new(:hash => entry_data, :url => url_task, :id_name => "task_ids", :category => "Task", :user => user, :pass => pass).get_summary
time = Minutedock.new(:hash => entry_data, :id_name => "duration", :category => "Time", :user => user, :pass => pass).get_summary
desc = Minutedock.new(:hash => entry_data, :id_name => "description", :category => "Description", :user => user, :pass => pass).get_summary
puts summaries = Minutedock.put_together(contact, project, task, time, desc)

client = HipChat::Client.new("6ece3454ac2e42e41faa3f384d5957")
summaries.map { |summary|
	client["test"].send('Ayumi Udaka', summary)
}
