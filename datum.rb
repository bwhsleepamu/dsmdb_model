class Datum < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :event_id, :unit_id, :documentation_id,  :title, :num_data, :text_data, :description, :time_data, :unit_name, :source_id, :missing

  belongs_to :data_unit, :foreign_key => "unit_id"
  belongs_to :event
  belongs_to :source
  belongs_to :documentation
  
  attr_accessor :unit_name
  
  before_save :assign_unit
  
#  accepts_nested_attributes_for :source
  scope :published_since, lambda { |ago|
    published.where("posts.published_at >= ?", ago)
  }

  def self.titles
    self.select("unique title").order("title asc").map(&:title)
  end

  def value
    
    # make sure one and only one field has a value
    if (num_data.nil? && text_data.nil? && time_data.nil?) and not missing
      CUSTOM_LOGGER.error "NO DATA VALUE! #{datum_id} #{time_data.nil?} #{missing}"
      raise StandardError, "No data value in datum object and no missing data flag"
    end
    
    if missing
      "N/A - Data Missing"
    else
      to_formatted_string
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
      when "date of birth", "admit date"
        time_data.strftime('%x')
      when "gender", "ethnic category"
        text_data.tr('_', ' ')
      when "weight", "height", "naps per week", "owl lark score", "blood pressure diastolic", "blood pressure systolic", "heart rate", "suite number"
        number_to_human(num_data)
      when "race"
        r = YAML::load(text_data)
        r.join(", ")
      else
        if !num_data.nil?
          num_data
        elsif !text_data.nil?
          text_data
        elsif !time_data.nil?
          time_data.strftime('%X')
        else
          "N/A - Data Missing"
        end
    end
  end
end
