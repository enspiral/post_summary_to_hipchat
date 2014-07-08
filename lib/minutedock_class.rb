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