class Source < ActiveRecord::Base
  attr_accessible :user, :source_type, :reference, :description
end
