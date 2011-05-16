class Datum < ActiveRecord::Base
  attr_accessible :event_id, :unit_id, :title, :numeric, :char, :description
end
