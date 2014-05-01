require 'open-uri'
require 'date'
require 'hipchat'
require 'json/pure'


SEPARATOR = ":"
MINUTEDOCK_URL = "https://minutedock.com/api/v1/"

yesterday = (Date.today - 1).strftime('%d%b%Y')
url_entry = "#{MINUTEDOCK_URL}entries.json?users=18590&from=#{yesterday}"
url_contact = "#{MINUTEDOCK_URL}contacts.json"
url_project = "#{MINUTEDOCK_URL}projects.json"
url_task = "#{MINUTEDOCK_URL}tasks.json"

def get_data(url)
	user = "ayumi.highroof@gmail.com"
	pass = "minute4649"
	result = open(url, :http_basic_authentication => [user, pass]).read
	json = JSON.parser.new(result)
	hash = json.parse()
end

def find_name_by_id(hash, id)
	hash.reject! { |data| return data["name"] if data["id"] == id }
end

client = HipChat::Client.new("6ece3454ac2e42e41faa3f384d5957")
client["Craftworks General"].send('Ayumi Udaka', "the time summary of yesterday")

hash_entry = get_data(url_entry)
hash_entry.map { |data|
	contact_id = data["contact_id"]
	project_id = data["project_id"]
	task_ids = data["task_ids"]

	time = data["duration"] / 60 / 60.0

	hash_contact = get_data(url_contact)
	contact = find_name_by_id(hash_contact, contact_id)

	if contact
		contact = "Contact" + SEPARATOR + contact
	else
		contact = "No Contact"
	end

	hash_project = get_data(url_project)
	project = find_name_by_id(hash_project, project_id)

	if project
		project = "Project" + SEPARATOR + project
	else
		project = "No Project"
	end

	hash_task = get_data(url_task)
	task = task_ids.map { |task_id| find_name_by_id(hash_task, task_id) }.join(",")

	if task
		task = "Task" + SEPARATOR + task
	else
		task = "No task"
	end

	description = "Description" + SEPARATOR + data["description"]
	time = "Time" + SEPARATOR + "#{time.round(1)}h"

	total = contact + "  " + project + "  " + task + "  " + description + "  " + time
	client["Craftworks General"].send('Ayumi Udaka', total)
}

