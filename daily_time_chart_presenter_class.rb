require 'googlecharts'

class DailyTimeChartPresenter
  def generate_pie_chart_url(title, legends, data)
    Gchart.pie( :size => '500x500', 
                :title => title,
                :bg => {:color => 'efefef', :type => 'gradient'},
                :color =>'0000FF',
                :legend => legends,
                :data => data)
  end

  def generate_bar_chart_url(title, legends, labels, bill, unbill, limit_number = 2)
    display_labels = []
    charts = []
    billable = []
    unbillable = []

    until labels.length <= 0
      if labels.length >= limit_number
        limit_number.times{ |i| 
            display_labels << labels[i]
            billable <<  bill[i]
            unbillable << unbill[i]
        }
        labels = labels - display_labels
        bill = bill - billable
        unbill = unbill -unbillable
      else
        display_labels = labels
        billable = bill
        unbillable = unbill
        labels = ""
      end

     charts << Gchart.bar( :size => '700x400', 
                    :data => [billable, unbillable], 
                    :bar_width_and_spacing => '15,45',
                    :stacked => false,
                    :max_value => 15,
                    :theme => :pastel,
                    :title => title,
                    :axis_with_labels => ['x','y'],
                    :axis_labels => [display_labels, [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]],
                    :legend => legends, 
                    :bg => {:color => '76A4FB', :type => 'gradient'},
                    :bar_colors => 'ff0000,00ff00')

        display_labels.clear
        billable.clear
        unbillable.clear

    end
charts
  end

end