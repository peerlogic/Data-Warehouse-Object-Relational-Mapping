class Task < ActiveRecord::Base
	has_many :critiques
	has_many :artifacts, foreign_key: 'submitted_in_task_id'
end