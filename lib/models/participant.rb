class Participant < ActiveRecord::Base
  has_many :actor_participants
end
