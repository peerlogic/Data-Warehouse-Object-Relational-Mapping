require 'active_record'
require 'json'

Dir['./models/*.rb'].each { |file| require_relative file }

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host: 	  'localhost',
  username: 'root',
  password: '',
  database: 'data_warehouse'
)

Task.all.each_with_index do |task, index|
  print '.' if index % 10 == 0
  next if task.artifacts.count == 0 || !task.id.include?('EZ-')
  task_hash = { 'critiques' => [] }
  task.artifacts.each do |artifact|
    uniq_accessor_actor_ids = artifact.critiques.map(&:assessor_actor_id).uniq!
    next if uniq_accessor_actor_ids.nil?
    uniq_accessor_actor_ids.each do |assessor_actor_id|
      total_score = 0
      max_total_score = 0
      assessee_actor_id = ''
      # TODO: latest critique for same artifact and assessor
      Critique.where(assessee_artifact_id: artifact.id, assessor_actor_id: assessor_actor_id).each do |critique|
        assessee_actor_id = critique.assessee_actor_id if assessee_actor_id.empty?
        total_score += critique.score.to_i
        max_total_score += critique.criterion.max_score.to_i
      end
      # convert assessees from teams to participants
      reviewer_actor_id = ActorParticipant.where(actor_id: assessor_actor_id).first.participant.id
      ActorParticipant.where(actor_id: assessee_actor_id).each do |ap|
        task_hash['critiques'] << { 'reviewer_actor_id' => reviewer_actor_id,
                                    'reviewee_actor_id' => ap.participant.id,
                                    'score'				=> total_score * 100.0 / max_total_score }
      end
    end
  end
  File.open("../output/#{task.id}.json", 'w') do |f|
    f.write(JSON.pretty_generate(task_hash))
  end
end
