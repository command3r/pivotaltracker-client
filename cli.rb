class ListView < Struct.new(:items)
  def render
    items.map do |item|
      puts <<-EOD
 - #{item['id'].to_s.ljust(8, " ")} #{item['name']}
      EOD
    end
  end
end

class StoriesView < Struct.new(:stories)
  def render
    puts "Current iteration:"
    stories.each do |story|
      puts <<-EOD
 - #{story['id'].to_s.ljust(8, " ")} #{story['name']}
   #{story['current_state']} #{story['story_type']}
      EOD
    end
  end
end
