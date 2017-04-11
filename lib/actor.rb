class Actor < ActiveRecord::Base
	has_many :actor_participants
	has_many :critiques_as_assessor, class_name: 'critique', foreign_key: 'assessor_actor_id'
	has_many :critiques_as_assessee, class_name: 'critique', foreign_key: 'assessee_actor_id'
end