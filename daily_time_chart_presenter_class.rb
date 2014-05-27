require 'googlecharts'

class DailyTimeChartPresenter
  def generate_pie_chart_url(title, legends, data)
    Gchart.pie( :size => '500x500', 
                :title => title,
                :bg => {:color => 'efefef'},
                :bar_colors =>['0000FF', '00FF00', 'FFFF00', 'FF0000', 'FF00FF','00FFFF'],
                :legend => legends,
                :data => data)
  end

  def generate_bar_chart_url(title, legends, labels, *data)
    Gchart.bar( :size => '700x400', 
                :data => data, 
                :bar_width_and_spacing => '15,45',
                :stacked => false,
                :max_value => 15,
                :theme => :pastel,
                :title => title,
                :axis_with_labels => ['x','y'],
                :axis_labels => [labels, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]],
                :legend => legends,
                :bg => {:color => 'efefef'},
                :bar_colors => 'ff0000,0000ff')
  end

  def generate_person_time_bar_chart(title, legends, labels, limit_number = 8, bill, unbill)
    charts = []
    display_labels = []
    billable = []
    unbillable = []


    until labels.length <= 0
      if labels.length >= limit_number
        limit_number.times{ |i| 
            display_labels << labels[i]
            billable << bill[i]
            unbillable << unbill[i]
        }
        labels = labels - display_labels
        bill.slice!(0...limit_number)
        unbill.slice!(0...limit_number)
      else
        display_labels = labels
        billable = bill
        unbillable = unbill
        labels = ""
      end

     charts << generate_bar_chart_url(title, legends, display_labels, billable, unbillable)

        display_labels.clear
        billable.clear
        unbillable.clear

    end
    charts
  end
end