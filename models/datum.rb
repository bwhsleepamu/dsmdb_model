class Datum < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :event_id, :unit_id, :title, :numeric, :char, :description, :timepoint, :unit_name, :source_id, :missing
  
  belongs_to :data_unit, :foreign_key => "unit_id"
  belongs_to :event
  belongs_to :source
  
  attr_accessor :unit_name
  
  before_save :assign_unit
  
  accepts_nested_attributes_for :source
    
  def value
    
    # make sure one and only one field has a value
    if (numeric.nil? && char.nil? && timepoint.nil?) and not missing
      CUSTOM_LOGGER.error "NO DATA VALUE! #{datum_id} #{timepoint.nil?} #{missing}"     
      raise StandardError, "No data value in datum object and no missing data flag"
    end
    
    if missing
      "N/A - Data Missing"
    else
      to_formatted_string
#    elsif !numeric.nil?
#      numeric
#    elsif !char.nil?
#      char.tr('_', ' ')
#    else
#      timepoint
    end
  end
  
  private 
  
  def assign_unit
    if self.unit_name
      u = DataUnit.find_or_create_by_name(self.unit_name)
      self.data_unit = u
    end
  end
  
  def to_formatted_string
    # special format needs first
    case title
      when "date of birth"
        timepoint.strftime('%x')
      when "gender", "ethnic category"
        char.tr('_', ' ')
      when "weight", "height", "naps per week", "owl lark score", "blood pressure diastolic", "blood pressure systolic", "heart rate"
        number_to_human(numeric)
      when "race"
        r = YAML::load(char)
        r.join(", ")
      else
        timepoint.strftime('%X')   
    end
  end
end
