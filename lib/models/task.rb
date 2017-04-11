class Task < ActiveRecord::Base
	has_many :critiques, foreign_key: 'create_in_task_id'
	has_many :artifacts, foreign_key: 'submitted_in_task_id'
end