class Source < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :user, :source_type, :reference, :description
  
  has_many :events
  has_many :data
  
  def self.create_source?(attr)
    unless attr.nil?
     unless (attr[:source_type].empty? and attr[:source_type].empty? and attr[:description].empty?)
        return true
      end
    end
    
    return false
  end

  # Given a user, source type, and source reference, determine whether source is already in database
  #   if so, return it.
  #   if not, create new source and return it
  # This function is ideal for computer file sources
  # WARNING! Function returns first source that matches given parameters - if parameters are not strict
  # enough, you might be left with an unsuitable source.

  # Refactor into scope!!
  def self.find_or_create(params)
    s = Source.where(params)

    if s.length > 1
      # For now, log when more than one matched source
      # Depending on strictness of parameters, there might be many sources that match
      CUSTOM_LOGGER.info "More than one matched source for #{params.to_yaml}"
    end
    s = s.first

    s.nil? ? Source.create(params) : s
  end
end
