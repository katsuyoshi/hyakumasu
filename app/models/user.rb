class User < ApplicationRecord

  STATE_IDLE = "idle"
  STATE_STARTED = "started"
  STATE_FINISHED = "finished"

  def col_numbers
    return [] if col_numbers_str.nil?
    col_numbers_str.split(",").map(&:to_i)
  end
  
  def col_numbers= numbers
    self.col_numbers_str = numbers.map(&:to_s).join(",")
  end
  
  def row_numbers
    return [] if row_numbers_str.nil?
    row_numbers_str.split(",").map(&:to_i)
  end

  def row_numbers= numbers
    self.row_numbers_str = numbers.map(&:to_s).join(",")
  end
  

end
