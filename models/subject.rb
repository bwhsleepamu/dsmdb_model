class Subject < ActiveRecord::Base
  set_primary_key self.name.downcase+'_id'
  set_sequence_name 'id_seq'
  attr_accessible :subject_code, :study_id, :notes, :new_irb_attributes, :deleted_irb_ids, :pl_id
  
  validates :subject_code, :presence => true, :uniqueness => true
  
  # Associations
  belongs_to :study
  belongs_to :personnel, :foreign_key => "pl_id"
  has_many :events
  has_and_belongs_to_many :irbs
  
  
  # Callbacks
  after_update :save_irbs
  before_destroy :delete_irb_associations

  
  # Getters
  def demographics
     events.where(:name => "demographics").first
  end

  # computed information:
  def age
    if demographics
      admit_date = demographics.data.find_by_title("admit date").timepoint
      dob = demographics.data.find_by_title("date of birth").timepoint

      age = admit_date.year - dob.year

      # if admit date is before birthday, take one year away
      if admit_date.month < dob.month
        age -= 1
      elsif admit_date.month == dob.month
        if admit_date.day < dob.day
          age -= 1
        end
      end
    end
    age
  end

  # Setters
  def new_irb_attributes=(irb_attributes)
    # Either find existing Irb object or create new one, then add to study
    irb_attributes.each do |attr|
      unless (attr[:protocol_id].empty? || attr[:protocol_id].nil?)
        new_irb = Irb.find_or_create_by_protocol_id(attr[:protocol_id]) 
        irbs << new_irb unless irbs.include?(new_irb)
      end
    end
  end
  
  def deleted_irb_ids=(irb_ids)
    irb_ids = irb_ids.map(&:to_i)
    irbs_to_delete = irbs.find_all_by_irb_id(irb_ids)
    irbs.delete(irbs_to_delete)
  end
  
  # Helpers  
  def save_irbs
    irbs.each do |irb|
      irb.save(false)
    end
  end
  
  # make sure association table entries are deleted before the user is deleted.  
  # this enforces oracle foreign key constraints
  def delete_irb_associations
    self.irbs.delete(self.irbs)
  end
end
