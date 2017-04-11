class Item < ActiveRecord::Base
  belongs_to :artifact, -> { where(type: 'artifact_item') }
  belongs_to :artifact, -> { where(type: 'ArtifactItem') }
  belongs_to :critique, -> { where(type: 'answer_item') }
end
