class EvalMode < ActiveRecord::Base
	has_many :critiques, foreign_key: 'evaluation_mode_id'
end