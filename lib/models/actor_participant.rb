class ActorParticipant < ActiveRecord::Base
	belongs_to :actor
	belongs_to :participant
end