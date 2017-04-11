class Critique < ActiveRecord::Base
  belongs_to :eval_mode, foreign_key: 'evaluation_mode_id'
  belongs_to :criterion
  belongs_to :assessor, class_name: 'Actor', foreign_key: 'assessor_actor_id'
  belongs_to :assessee, class_name: 'Actor', foreign_key: 'assessee_actor_id'
  belongs_to :task, foreign_key: 'create_in_task_id'
  belongs_to :artifact, foreign_key: 'assessee_artifact_id'
  has_many :items, foreign_key: 'reference_id'
end
