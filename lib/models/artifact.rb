class Artifact < ActiveRecord::Base
  has_many :critiques, foreign_key: 'assessee_artifact_id'
  belongs_to :task, foreign_key: 'submitted_in_task_id'
  has_many :items, foreign_key: 'reference_id'
end
