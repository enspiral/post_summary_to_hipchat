require 'open-uri'
require 'date'
require 'active_support/time'
require 'hipchat'
require 'json/pure'
require './minutedock_class.rb'
require './daily_time_text_presenter_class.rb'
require './daily_time_chart_presenter_class.rb'


SEPARATOR = ":"
MINUTEDOCK_URL = "https://minutedock.com/api/v1/"

api_keys = []
project_name = []
project_time = []
personal_time = []
projects = []
time = []
bill = []
unbill = []

path_to_api = File.expand_path("~/post_summary_to_hipchat/api_keys.txt")
IO.foreach(path_to_api) { |key| api_keys << key.chomp.split(":") }

user = Minutedock.new
presenter = DailyTimeTextPresenter.new
chart_presenter = DailyTimeChartPresenter.new
client = HipChat::Client.new("6ece3454ac2e42e41faa3f384d5957")

class Time
    def convert_to_nz_time(time)
      time.in_time_zone("Wellington")
    end
end
nz_time = Time.new.convert_to_nz_time(Time.now)
yesterday = nz_time.to_date - 1

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

project_time.map { |project|
  projects << project[:project] + SEPARATOR + presenter.remove_decimal(presenter.convert_time(project[:time])).to_s
  time << project[:time]
}

personal_time.map { |personal|
  bill << presenter.convert_time(personal[:billiable])
  unbill << presenter.convert_time(personal[:unbilliable])
}

pie_chart = chart_presenter.generate_pie_chart_url("Hours Spent on Each Project Yesterday", projects, time)
bar_charts =  chart_presenter.generate_person_time_bar_chart("Hours Worked by Each Person Yesterday",['billable', 'unbillable'], personal, bill, unbill)


client["BotLab"].send('Minutedock', pie_chart, :message_format => 'text')
bar_charts.map{ |bar_chart|
  client["BotLab"].send('Minutedock', bar_chart, :message_format => 'text')
}