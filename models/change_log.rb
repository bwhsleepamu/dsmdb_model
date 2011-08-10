class ChangeLog < ActiveRecord::Base
  set_primary_key self.name.underscore+'_id'
  set_sequence_name 'changelog_id_seq'
  attr_accessible :reference_id, :user, :time_stamp, :change_type
    
#  private
#  def set_user
#    self.user = Authorization.current_user
#  end
end
